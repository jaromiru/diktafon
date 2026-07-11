/// Regression test for tape seeking (§5.3): scrubbing/rewinding used to land
/// at 0:00 with mpv "error running command" — media_kit turns any indexed
/// seek into an mpv playlist-entry reload that rejects in-file seeks until
/// its playback restart finishes (see TapePlayerService._seekTo).
///
/// Seeds a cassette with three synthesized tone memos (8 s / 6 s / 10 s)
/// and drives the real app: a pre-play seek (the player is still inactive —
/// it must survive the first play instead of restarting at 0:00), play,
/// drag-scrub across two memo boundaries, rewind across boundaries,
/// tap-to-jump — asserting the playhead lands where aimed. The fixtures are
/// pure-Dart WAV, so this runs against every just_audio backend (mpv on
/// Linux, AVPlayer on iOS — whose seek semantics differ; §15 iOS port):
///
///   DIKTAFON_TEST_DIR=/tmp/dk_seek \
///   flutter test integration_test/seek_verify_test.dart -d linux
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:diktafon/app.dart';
import 'package:diktafon/application/providers.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/files/audio_file_store.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/presentation/widgets/cassette_card.dart';
import 'package:diktafon/presentation/widgets/deck.dart';
import 'package:diktafon/presentation/widgets/timeline_bar.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'test_env.dart';

final _boundaryKey = GlobalKey();
late Directory _workDir;

Future<void> _shot(WidgetTester tester, String name) async {
  await _settle(tester);
  final dir = Directory('${_workDir.path}/shots')..createSync(recursive: true);
  final boundary =
      _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<void> _settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Real-time wait (audio plays on the wall clock) while keeping frames alive.
Future<void> _wait(WidgetTester tester, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
}

Finder _key(DeckGlyph glyph) =>
    find.byWidgetPredicate((w) => w is DeckKey && w.glyph == glyph);

/// Three tone memos, tape = 0–8 s | 8–14 s | 14–24 s. Synthesized in-process
/// (WAV is sample-exact — no AAC priming-frame padding to skew boundaries).
Future<List<String>> _renderTones() async {
  final dir = Directory('${_workDir.path}/tones')..createSync(recursive: true);
  final specs = [(440, 8), (660, 6), (880, 10)];
  final paths = <String>[];
  for (var i = 0; i < specs.length; i++) {
    final (hz, seconds) = specs[i];
    final path = '${dir.path}/memo$i.wav';
    File(path).writeAsBytesSync(_toneWav(hz: hz, seconds: seconds));
    paths.add(path);
  }
  return paths;
}

/// Minimal RIFF/WAVE writer: [seconds] of a [hz] sine, 16-bit PCM mono.
Uint8List _toneWav({required int hz, required int seconds, int rate = 44100}) {
  final samples = seconds * rate;
  final data = ByteData(44 + samples * 2);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little); // fmt chunk size
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little); // byte rate
  data.setUint16(32, 2, Endian.little); // block align
  data.setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  data.setUint32(40, samples * 2, Endian.little);
  for (var i = 0; i < samples; i++) {
    final v = math.sin(2 * math.pi * hz * i / rate);
    data.setInt16(44 + i * 2, (v * 0.4 * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isLinux) {
      JustAudioMediaKit.ensureInitialized(
        linux: true,
        windows: false,
        libmpv: testEnv('LIBMPV_PATH'),
      );
    }
    final base = testEnv('DIKTAFON_TEST_DIR');
    if (base != null) {
      _workDir = Directory(base);
      if (_workDir.existsSync()) _workDir.deleteSync(recursive: true);
      _workDir.createSync(recursive: true);
    } else {
      _workDir = Directory.systemTemp.createTempSync('diktafon_seek_');
    }
  });

  testWidgets(
    'scrub / rewind / tap-jump land where aimed, across memo boundaries',
    (tester) async {
      final db = AppDatabase.forTesting(
          NativeDatabase(File('${_workDir.path}/diktafon.db')));
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioFileStoreProvider.overrideWithValue(AudioFileStore(
            Directory('${_workDir.path}/audio')..createSync(recursive: true))),
      ]);
      addTearDown(container.dispose);

      // — Seed: one cassette, three tone memos → tape 0–8 s | 8–14 s | 14–24 s —
      final tonePaths = await _renderTones();
      final cassette =
          await container.read(cassetteRepositoryProvider).create();
      final memoRepo = container.read(memoRepositoryProvider);
      const durations = [8000, 6000, 10000];
      for (var i = 0; i < 3; i++) {
        await memoRepo.insert(Memo(
          id: 'memo-$i',
          cassetteId: cassette.id,
          filePath: tonePaths[i],
          durationMs: durations[i],
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(1700000000000 + i * 60000),
          status: MemoStatus.stored,
        ));
      }

      // M4: skip the first-run flow — this test exercises the app proper.
      await db.into(db.settingsEntries).insert(
          const SettingRow(key: 'firstRunDone', value: '1'));

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(key: _boundaryKey, child: const DiktafonApp()),
      ));
      await _settle(tester);

      await tester.tap(find.byType(CassetteCard));
      await _settle(tester);

      final player = container.read(tapePlayerProvider);
      expect(player.tape.totalDurationMs, 24000);
      final rect = tester.getRect(find.byType(TimelineBar));

      // — Regression: seek before the first play (the platform player is
      //   still inactive, preload: false) — pressing play must continue
      //   from the sought spot, not restart at 0:00 (just_audio wipes the
      //   pending initial position on an idle seek). —
      final preplay = await tester
          .startGesture(Offset(rect.left + rect.width * .05, rect.center.dy));
      for (final f in [.08, .10, .125]) {
        await preplay.moveTo(Offset(rect.left + rect.width * f, rect.center.dy));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await preplay.up();
      await _wait(tester, 500);
      var s = player.state;
      expect(s.playing, isFalse);
      expect(s.globalMs, closeTo(3000, 900),
          reason: 'the pre-play seek target is reflected while paused');

      await tester.tap(_key(DeckGlyph.play));
      await _wait(tester, 1500);
      s = player.state;
      expect(s.playing, isTrue);
      expect(s.globalMs, greaterThan(3200),
          reason: 'play must continue from the pre-play seek, not 0:00');
      expect(s.globalMs, closeTo(4500, 1500));

      // Back to the top for the rest of the script (a tap inside memo 1
      // jumps to its start = 0:00).
      await tester.tap(_key(DeckGlyph.pause));
      await _wait(tester, 300);
      await tester.tapAt(Offset(rect.left + rect.width * .02, rect.center.dy));
      await _wait(tester, 500);

      // — Play from the top; confirm real audio position advances —
      await tester.tap(_key(DeckGlyph.play));
      await _wait(tester, 1500);
      s = player.state;
      expect(s.playing, isTrue);
      expect(s.memoIndex, 0);
      expect(s.globalMs, greaterThan(700));

      // — Scrub while playing: drag 5 % → 75 % (≈ 18 s, memo 3 local 4 s),
      //   many drag updates, crossing two memo boundaries —
      final gesture = await tester
          .startGesture(Offset(rect.left + rect.width * .05, rect.center.dy));
      const steps = 35;
      for (var i = 1; i <= steps; i++) {
        await gesture.moveBy(Offset(rect.width * .70 / steps, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await _wait(tester, 1000); // let the cross-memo seek settle
      await _shot(tester, '20-after-scrub-75pct');

      s = player.state;
      expect(s.memoIndex, 2, reason: 'scrub target ≈18 s is inside memo 3');
      expect(s.globalMs, closeTo(18000, 2500),
          reason: 'playhead must land where dragged, not at 0:00');

      // — The old bug: playback snapped back to the memo start. Position
      //   must keep advancing from the scrub target instead. —
      final afterScrub = s.globalMs;
      await _wait(tester, 1500);
      s = player.state;
      expect(s.playing, isTrue);
      expect(s.globalMs - afterScrub, closeTo(1500, 1000),
          reason: 'audio must continue from the scrub target');

      // — Pause for deterministic probes —
      await tester.tap(_key(DeckGlyph.pause));
      await _wait(tester, 500);
      final paused = player.state;
      expect(paused.playing, isFalse);

      // — Probe: rewind −15 s crosses two boundaries back into memo 1 —
      await tester.tap(_key(DeckGlyph.rewind));
      await _wait(tester, 1000);
      s = player.state;
      expect(s.memoIndex, 0, reason: 'rewind lands in memo 1');
      expect(s.globalMs, closeTo(paused.globalMs - 15000, 1500),
          reason: 'rewind must land mid-memo, not at its start');
      await _shot(tester, '21-after-rewind');

      // — Probe: tap at 50 % (inside memo 2) jumps to memo 2 start (8 s) —
      await tester.tapAt(Offset(rect.left + rect.width * .50, rect.center.dy));
      await _wait(tester, 800);
      s = player.state;
      expect(s.memoIndex, 1);
      expect(s.globalMs, closeTo(8000, 800),
          reason: 'tap jumps to the start of the tapped memo');

      // — Probe: rapid zig-zag scrub while paused, ending at 30 % (7.2 s) —
      final zig = await tester
          .startGesture(Offset(rect.left + rect.width * .50, rect.center.dy));
      for (final f in [.65, .25, .70, .20, .60, .30]) {
        await zig.moveTo(Offset(rect.left + rect.width * f, rect.center.dy));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await zig.up();
      await _wait(tester, 1000);
      s = player.state;
      expect(s.playing, isFalse, reason: 'scrubbing must not start playback');
      expect(s.memoIndex, 0);
      expect(s.globalMs, closeTo(7200, 1500),
          reason: 'zig-zag scrub settles on the final drag position');
      await _shot(tester, '22-after-zigzag-30pct');

      // — Resume: plays from the scrubbed spot —
      await tester.tap(_key(DeckGlyph.play));
      await _wait(tester, 1200);
      s = player.state;
      expect(s.playing, isTrue);
      expect(s.globalMs, closeTo(7200 + 1200, 1800));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
