/// Transcription quality bench (docs/features/noise-robust-transcription.md,
/// phase 0): runs one *variant* — a whisper model + engine build + optional
/// ffmpeg decode filter — over the verified fixtures in `quality_test/` and
/// scores WER/CER against the sibling `.txt` references. (The phase-0 LLM
/// cleanup mode left with the §6.8 feature — the bench proved it WER-inert.)
///
/// Results are written after every clip to
/// `<out>/<variant>.json` so an interrupted sweep resumes where it stopped
/// (existing clips whose config matches are not re-run). Raw whisper
/// transcripts (with word timings) are stored in the JSON.
///
/// Everything is env-driven — see `test/quality/README.md`.
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/audio/pcm_highpass.dart';
import 'package:diktafon/services/providers/whisper/whisper_worker.dart';
import 'package:ffi/ffi.dart';

import 'wer.dart';

class QualityConfig {
  QualityConfig({
    required this.variant,
    required this.fixturesDir,
    required this.outDir,
    required this.whisperLib,
    required this.whisperModel,
    required this.ffmpegFilter,
    required this.forceLanguage,
    required this.note,
    this.rescore = false,
    this.highPassHz,
    this.beamSize = 0,
    this.vadModelPath,
  });

  /// Names the run; results land in `<outDir>/<variant>.json`.
  final String variant;
  final Directory fixturesDir;
  final Directory outDir;

  final String? whisperLib;
  final String? whisperModel;

  /// Extra `-af` chain applied during decode (bench-only seam for HPF /
  /// denoise ablations; production mobile decoders have no such hook).
  final String? ffmpegFilter;

  /// `true` = pass the clip's filename language to whisper (the Settings
  /// override path); default is auto-detect (D8, production default).
  final bool forceLanguage;

  /// Free-form provenance (branch/commit), stored in the results file.
  final String? note;

  /// Re-score cached clips from their stored hypothesis text (scorer
  /// changes) instead of skipping them.
  final bool rescore;

  /// Cutoff of the Dart transcription-path high-pass (quality/hpf branch);
  /// null = off.
  final double? highPassHz;

  /// > 1 = beam-search decoding with this beam size (quality/beam branch).
  final int beamSize;

  /// Silero VAD ggml model gating inference to detected speech regions;
  /// null = off. Tuned params are baked into the shim (DK_WHISPER_VAD_*
  /// env knobs still override for sweeps).
  final String? vadModelPath;

  static QualityConfig? fromEnv(Map<String, String> env) {
    final variant = env['DIKTAFON_QUALITY_VARIANT'];
    final dir = env['DIKTAFON_QUALITY_DIR'];
    if (variant == null || dir == null) return null;
    return QualityConfig(
      variant: variant,
      fixturesDir: Directory(dir),
      outDir: Directory(env['DIKTAFON_QUALITY_OUT'] ?? '$dir/results'),
      whisperLib: env['DIKTAFON_LIBWHISPER'],
      whisperModel: env['DIKTAFON_WHISPER_MODEL'],
      ffmpegFilter: env['DIKTAFON_QUALITY_FILTER'],
      forceLanguage: env['DIKTAFON_QUALITY_LANG'] == 'file',
      note: env['DIKTAFON_QUALITY_NOTE'],
      rescore: env['DIKTAFON_QUALITY_RESCORE'] == '1',
      highPassHz: double.tryParse(env['DIKTAFON_QUALITY_HPF'] ?? ''),
      beamSize: int.tryParse(env['DIKTAFON_QUALITY_BEAM'] ?? '') ?? 0,
      vadModelPath: env['DIKTAFON_QUALITY_VAD'],
    );
  }

  /// The config facets that make cached per-clip results reusable.
  Map<String, dynamic> fingerprint() => {
        'whisperModel':
            whisperModel == null ? null : File(whisperModel!).uri.pathSegments.last,
        'ffmpegFilter': ffmpegFilter,
        'forceLanguage': forceLanguage,
        if (highPassHz != null) 'highPassHz': highPassHz,
        if (beamSize > 1) 'beamSize': beamSize,
        if (vadModelPath != null)
          'vad': File(vadModelPath!).uri.pathSegments.last,
      };
}

class Clip {
  const Clip(this.name, this.audioPath, this.reference, this.language);

  final String name;
  final String audioPath;
  final String reference;

  /// From the file name (`*_cs*` / `*_en*`) — ground truth for detection.
  final String language;
}

List<Clip> discoverClips(Directory fixtures) {
  final clips = <Clip>[];
  for (final entry in fixtures.listSync()) {
    if (entry is! File || !entry.path.endsWith('.m4a')) continue;
    final name = entry.uri.pathSegments.last.replaceAll('.m4a', '');
    final ref = File('${fixtures.path}/$name.txt');
    if (!ref.existsSync()) continue;
    final language = name.contains('_cs')
        ? 'cs'
        : name.contains('_en')
            ? 'en'
            : 'unknown';
    clips.add(Clip(name, entry.path, ref.readAsStringSync().trim(), language));
  }
  clips.sort((a, b) => a.name.compareTo(b.name));
  return clips;
}

/// Mirrors the providers' thread policy (§6.5).
final int benchThreads = max(1, min(Platform.numberOfProcessors - 2, 8));

Future<void> runVariant(QualityConfig config) async {
  final clips = discoverClips(config.fixturesDir);
  if (clips.isEmpty) {
    throw StateError('no .m4a/.txt fixture pairs in ${config.fixturesDir.path}');
  }
  config.outDir.createSync(recursive: true);
  final outFile = File('${config.outDir.path}/${config.variant}.json');

  Map<String, dynamic> results;
  if (outFile.existsSync()) {
    results = jsonDecode(outFile.readAsStringSync()) as Map<String, dynamic>;
    final existing = jsonEncode(results['config']);
    final wanted = jsonEncode(config.fingerprint());
    if (existing != wanted) {
      throw StateError(
          'results file ${outFile.path} was produced by a different config:\n'
          '  existing: $existing\n  wanted:   $wanted\n'
          'delete the file (or rename the variant) to re-run');
    }
  } else {
    results = {
      'variant': config.variant,
      'config': config.fingerprint(),
      'note': config.note,
      'threads': benchThreads,
      'startedAt': DateTime.now().toIso8601String(),
      'clips': <String, dynamic>{},
    };
  }
  final clipResults = results['clips'] as Map<String, dynamic>;

  // Spawned lazily on first transcribe — a pure rescore run (all clips
  // cached) needs no engine lib at all.
  final whisper = WhisperWorker(config.whisperLib ?? '');
  final cancelFlag = calloc<Int32>();
  try {
    for (final clip in clips) {
      if (clipResults.containsKey(clip.name)) {
        if (config.rescore) {
          final entry = clipResults[clip.name] as Map<String, dynamic>;
          score(entry, clip, entry['text'] as String);
          stdout.writeln('[bench] ${clip.name}: rescored → WER '
              '${((entry['wer'] as double) * 100).toStringAsFixed(1)}%');
        } else {
          stdout.writeln('[bench] ${clip.name}: cached, skipping');
        }
        continue;
      }
      stdout.writeln('[bench] ${clip.name}: running…');
      final entry = <String, dynamic>{'language': clip.language};

      final pcmPath = '${Directory.systemTemp.path}/dk_quality_'
          '${clip.name}.f32';
      final decodeWatch = Stopwatch()..start();
      await decodeToF32(clip.audioPath, pcmPath, config.ffmpegFilter);
      if (config.highPassHz != null) {
        await highPassPcmFile(pcmPath, cutoffHz: config.highPassHz!);
      }
      entry['decodeMs'] = decodeWatch.elapsedMilliseconds;

      final watch = Stopwatch()..start();
      final raw = await whisper.transcribe(
        modelPath: config.whisperModel!,
        pcmPath: pcmPath,
        languageCode: config.forceLanguage ? clip.language : null,
        cancelFlagAddress: cancelFlag.address,
        threads: benchThreads,
        beamSize: config.beamSize,
        vadModelPath: config.vadModelPath,
      );
      entry['transcribeMs'] = watch.elapsedMilliseconds;
      entry['detectedLanguage'] = raw.languageCode;
      // Decoder confidence per kept segment: recorded for post-hoc
      // threshold analysis, not filtered here.
      entry['segmentConfidence'] = [
        for (final (i, c) in whisper.lastSegmentConfidence.indexed)
          {
            'noSpeechProb': c.noSpeechProb,
            'avgTokenP': c.avgTokenP,
            'text': raw.segments[i].words.map((w) => w.text).join(' '),
          },
      ];
      File(pcmPath).deleteSync();
      entry['transcript'] = raw.toJson();
      entry['rawText'] = transcriptText(raw);

      score(entry, clip, transcriptText(raw));

      clipResults[clip.name] = entry;
      results['aggregate'] = aggregate(clipResults);
      results['updatedAt'] = DateTime.now().toIso8601String();
      outFile.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(results));
      stdout.writeln('[bench] ${clip.name}: WER '
          '${((entry['wer'] as double) * 100).toStringAsFixed(1)}% '
          '(${(entry['substitutions'] as int) + (entry['deletions'] as int) + (entry['insertions'] as int)}'
          '/${entry['referenceWords']})');
    }

    results['aggregate'] = aggregate(clipResults);

    results['completed'] = true;
    results['updatedAt'] = DateTime.now().toIso8601String();
    outFile
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
    stdout.writeln('[bench] variant ${config.variant} done → ${outFile.path}');
    final agg = results['aggregate'] as Map<String, dynamic>;
    stdout.writeln('[bench] pooled WER ${(agg['wer'] * 100).toStringAsFixed(1)}%'
        ' (cs ${(agg['werCs'] * 100).toStringAsFixed(1)}%,'
        ' en ${(agg['werEn'] * 100).toStringAsFixed(1)}%)');
  } finally {
    calloc.free(cancelFlag);
    await whisper.dispose();
  }
}

/// Scores [text] against the clip's reference into [entry] (in place —
/// also used to re-score cached entries after scorer changes).
void score(Map<String, dynamic> entry, Clip clip, String text) {
  final words = wordErrors(clip.reference, text, language: clip.language);
  final chars = charErrors(clip.reference, text, language: clip.language);
  entry['reference'] = clip.reference;
  entry['text'] = text;
  entry['wer'] = words.rate;
  entry['substitutions'] = words.substitutions;
  entry['deletions'] = words.deletions;
  entry['insertions'] = words.insertions;
  entry['referenceWords'] = words.referenceLength;
  entry['cer'] = chars.rate;
}

String transcriptText(Transcript t) => t.segments
    .map((s) => s.words.map((w) => w.text).join(' '))
    .where((line) => line.isNotEmpty)
    .join('\n');

/// Pooled rates (summed errors over summed reference words — clip length
/// weighs in, unlike a mean of per-clip rates).
Map<String, dynamic> aggregate(Map<String, dynamic> clips) {
  var errors = 0, refWords = 0;
  final perLanguage = <String, List<int>>{}; // lang → [errors, refWords]
  var misdetected = 0;
  for (final entry in clips.values) {
    final clip = entry as Map<String, dynamic>;
    final clipErrors = (clip['substitutions'] as int) +
        (clip['deletions'] as int) +
        (clip['insertions'] as int);
    final clipRef = clip['referenceWords'] as int;
    errors += clipErrors;
    refWords += clipRef;
    final lang = clip['language'] as String;
    perLanguage.putIfAbsent(lang, () => [0, 0]);
    perLanguage[lang]![0] += clipErrors;
    perLanguage[lang]![1] += clipRef;
    if (clip['detectedLanguage'] != lang) misdetected++;
  }
  double rate(List<int>? bucket) =>
      bucket == null || bucket[1] == 0 ? 0 : bucket[0] / bucket[1];
  return {
    'wer': refWords == 0 ? 0 : errors / refWords,
    'werCs': rate(perLanguage['cs']),
    'werEn': rate(perLanguage['en']),
    'clips': clips.length,
    'misdetectedLanguage': misdetected,
  };
}

/// ffmpeg decode to raw f32le 16 kHz mono — the desktop production path
/// (FfmpegPcmDecoder) plus the bench-only optional `-af` hook.
Future<void> decodeToF32(
    String audioPath, String pcmPath, String? filter) async {
  final result = await Process.run('ffmpeg', [
    '-y',
    '-v', 'error',
    '-i', audioPath,
    if (filter != null) ...['-af', filter],
    '-f', 'f32le',
    '-ac', '1',
    '-ar', '16000',
    pcmPath,
  ]);
  if (result.exitCode != 0) {
    throw ProcessException(
        'ffmpeg', const [], result.stderr.toString(), result.exitCode);
  }
}
