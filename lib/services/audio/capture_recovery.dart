/// Salvaging captures the OS killed mid-recording (D13/§14): the recorder
/// drops a marker file next to the WAV when capture starts and the
/// controller removes it once the memo row is safely in the DB — so at the
/// next launch, every marker still on disk names a capture that never made
/// it to the tape. Recovery repairs the WAV's header, inserts the memo, and
/// re-enters the enrichment pipeline. Runs before the orphan sweep (which
/// would otherwise eventually delete exactly these files) and before the UI
/// is up (so a fresh capture can never race the scan).
library;

import 'dart:convert';
import 'dart:io';

import '../../data/files/audio_file_store.dart';
import '../../data/repositories/cassette_repository.dart';
import '../../data/repositories/memo_repository.dart';
import '../../domain/models.dart';
import 'wav_repair.dart';

/// The marker sits right next to the capture: `<memoId>.wav.capture`.
String captureMarkerPath(String wavPath) => '$wavPath.capture';

/// Written by the recorder the moment capture starts.
Future<void> writeCaptureMarker({
  required String wavPath,
  required String memoId,
  required String cassetteId,
  required DateTime startedAt,
}) =>
    File(captureMarkerPath(wavPath)).writeAsString(jsonEncode({
      'memoId': memoId,
      'cassetteId': cassetteId,
      'startedAt': startedAt.millisecondsSinceEpoch,
    }));

/// Removed once the finished memo's row exists (or the capture is
/// discarded) — from then on the normal machinery owns the file.
Future<void> removeCaptureMarker(String wavPath) async {
  final marker = File(captureMarkerPath(wavPath));
  try {
    if (await marker.exists()) await marker.delete();
  } catch (_) {
    // Leftover markers resolve at the next launch's recovery pass.
  }
}

/// Ignores markers whose capture holds less than this much PCM — a kill in
/// the first instants of a recording left nothing worth keeping (16 kHz
/// mono s16 ≈ 32 bytes/ms).
const int _minDataBytes = 3200; // ~100 ms

class CaptureRecovery {
  CaptureRecovery({
    required this._files,
    required this._memos,
    required this._cassettes,
    required this._enqueueTranscription,
    required this._enqueueTranscode,
  });

  final AudioFileStore _files;
  final MemoRepository _memos;
  final CassetteRepository _cassettes;

  // Injected like the importer's (§8) — the unit-test seam, and recovery
  // must not depend on the queue's construction order at launch.
  final Future<void> Function(String memoId) _enqueueTranscription;
  final Future<void> Function(String memoId) _enqueueTranscode;

  /// Scans for leftover capture markers and turns each salvageable WAV into
  /// a regular memo. Returns how many memos were recovered. Best-effort per
  /// marker: one bad capture never sinks the rest.
  Future<int> recover() async {
    final root = Directory(_files.rootPath);
    if (!await root.exists()) return 0;
    final markers = <File>[];
    await for (final entry in root.list(recursive: true)) {
      if (entry is File && entry.path.endsWith('.wav.capture')) {
        markers.add(entry);
      }
    }
    if (markers.isEmpty) return 0;

    final existing = await _memos.allIds();
    var recovered = 0;
    for (final marker in markers) {
      try {
        if (await _recoverOne(marker, existing)) recovered++;
      } catch (_) {
        // A marker that fails to parse or insert is dropped with its
        // capture cleaned up by the next sweep — never crash the launch.
      }
    }
    return recovered;
  }

  Future<bool> _recoverOne(File marker, Set<String> existingMemoIds) async {
    final wavPath =
        marker.path.substring(0, marker.path.length - '.capture'.length);
    Map<String, dynamic>? data;
    try {
      data = (jsonDecode(await marker.readAsString()) as Map)
          .cast<String, dynamic>();
    } catch (_) {
      data = null;
    }
    final memoId = data?['memoId'] as String?;
    final cassetteId = data?['cassetteId'] as String?;
    final startedAt = data?['startedAt'] as int?;

    if (memoId == null || cassetteId == null) {
      await marker.delete(); // unreadable marker — nothing to recover
      return false;
    }
    if (existingMemoIds.contains(memoId)) {
      // Killed between the row insert and the marker removal — the memo is
      // already on the tape; the launch reconciles find its missing jobs.
      await marker.delete();
      return false;
    }
    if (!await _cassettes.exists(cassetteId)) {
      // The cassette went away (its dir was recreated by a re-import) —
      // there is no tape to put the capture on.
      await _discard(marker, wavPath);
      return false;
    }

    final info = await repairWav(wavPath);
    if (info == null || info.dataBytes < _minDataBytes) {
      await _discard(marker, wavPath); // nothing salvageable in the file
      return false;
    }

    // Mirror a normal stop (D7): createdAt is when the capture *ended* —
    // for a killed one, its start plus however much audio hit the disk.
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
        (startedAt ?? DateTime.now().millisecondsSinceEpoch) +
            info.durationMs);
    await _memos.insert(Memo(
      id: memoId,
      cassetteId: cassetteId,
      filePath: wavPath,
      durationMs: info.durationMs,
      createdAt: createdAt,
      status: MemoStatus.stored,
    ));
    await _cassettes.touch(cassetteId);
    await _enqueueTranscription(memoId);
    await _enqueueTranscode(memoId);
    await marker.delete();
    return true;
  }

  Future<void> _discard(File marker, String wavPath) async {
    final wav = File(wavPath);
    if (await wav.exists()) await wav.delete();
    await marker.delete();
  }
}
