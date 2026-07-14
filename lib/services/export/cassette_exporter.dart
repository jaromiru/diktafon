/// Cassette export (§8, data portability): audio + transcript + summary
/// bundled into a single `.zip` archive, for the user's own archival and
/// for re-import. Two views of the same data inside: `transcript.md` to
/// read, `cassette.json` to parse (and to import back).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';

/// User-facing strings inside the exported files; the UI passes its
/// localized set so the archive reads in the app's language.
class ExportLabels {
  const ExportLabels({
    this.untitled = 'Untitled cassette',
    this.exportedNote = _defaultExportedNote,
    this.summaryHeading = 'Summary',
    this.memoHeading = _defaultMemoHeading,
    this.notTranscribed = '(not transcribed)',
    this.noSpeech = '(no speech)',
  });

  final String untitled;
  final String Function(String date) exportedNote;
  final String summaryHeading;
  final String Function(int n, String date) memoHeading;
  final String notTranscribed;
  final String noSpeech;

  static String _defaultExportedNote(String date) =>
      'Exported from Diktafon on $date.';
  static String _defaultMemoHeading(int n, String date) => 'Memo $n — $date';
}

class CassetteExporter {
  const CassetteExporter({this.labels = const ExportLabels()});

  final ExportLabels labels;

  /// Bumped when `cassette.json` changes shape; the importer accepts
  /// anything ≤ its own version (absent → the first, pre-versioned cut).
  static const manifestVersion = 1;

  /// Exports every cassette in [items] into one `.zip` at [outputPath]
  /// (one `<label>/` folder each, same layout `exportCassette` writes).
  /// Audio is stored uncompressed — the m4a files dominate the archive and
  /// deflate would only burn CPU on them.
  Future<File> exportArchive({
    required List<({Cassette cassette, List<Memo> memos})> items,
    required String outputPath,
  }) async {
    final staging = await Directory.systemTemp.createTemp('diktafon_export_');
    try {
      for (final item in items) {
        await exportCassette(
            cassette: item.cassette, memos: item.memos, target: staging);
      }
      // Zipping a multi-hundred-MB library is seconds of pure CPU — off
      // the UI isolate, or the export screen freezes for its duration.
      final stagingPath = staging.path;
      await Isolate.run(() => ZipFileEncoder().zipDirectory(
          Directory(stagingPath),
          filename: outputPath,
          level: ZipFileEncoder.store));
      return File(outputPath);
    } finally {
      await staging.delete(recursive: true);
    }
  }

  /// Writes `<target>/<label>/{transcript.md, cassette.json, audio/…}` and
  /// returns the created directory. Never overwrites: an existing folder of
  /// the same name gets a ` (2)`-style suffix.
  Future<Directory> exportCassette({
    required Cassette cassette,
    required List<Memo> memos,
    required Directory target,
  }) async {
    final dir = await _claimDir(
        target, fileSafe(cassette.label ?? labels.untitled));
    final audioDir = Directory('${dir.path}/audio');
    await audioDir.create(recursive: true);

    final audioNames = <String, String?>{}; // memo id → exported file name
    for (var i = 0; i < memos.length; i++) {
      final memo = memos[i];
      final source = File(memo.filePath);
      // A memo whose audio vanished (e.g. metadata-only OS restore, §8)
      // still exports its transcript.
      if (!await source.exists()) {
        audioNames[memo.id] = null;
        continue;
      }
      final name = 'memo-${(i + 1).toString().padLeft(3, '0')}_'
          '${DateFormat('yyyy-MM-dd_HH-mm-ss').format(memo.createdAt)}.m4a';
      await source.copy('${audioDir.path}/$name');
      audioNames[memo.id] = name;
    }

    await File('${dir.path}/transcript.md')
        .writeAsString(_transcriptMd(cassette, memos));
    await File('${dir.path}/cassette.json').writeAsString(
        const JsonEncoder.withIndent('  ')
            .convert(_manifest(cassette, memos, audioNames)));
    return dir;
  }

  String _transcriptMd(Cassette cassette, List<Memo> memos) {
    final buffer = StringBuffer()
      ..writeln('# ${cassette.label ?? labels.untitled}')
      ..writeln()
      ..writeln(labels.exportedNote(_stamp(DateTime.now())))
      ..writeln();
    if (cassette.summary != null) {
      buffer
        ..writeln('## ${labels.summaryHeading}')
        ..writeln()
        ..writeln(cassette.summary)
        ..writeln();
    }
    for (var i = 0; i < memos.length; i++) {
      final memo = memos[i];
      buffer
        ..writeln('## ${labels.memoHeading(i + 1, _stamp(memo.createdAt))}')
        ..writeln();
      if (memo.memoSummary != null) {
        buffer
          ..writeln('> ${memo.memoSummary}')
          ..writeln();
      }
      final transcript = memo.transcript;
      buffer
        ..writeln(switch (transcript) {
          null => labels.notTranscribed,
          Transcript(isEmpty: true) => labels.noSpeech,
          _ => _plainText(transcript),
        })
        ..writeln();
    }
    return buffer.toString();
  }

  Map<String, Object?> _manifest(Cassette cassette, List<Memo> memos,
          Map<String, String?> audioNames) =>
      {
        'formatVersion': manifestVersion,
        'label': cassette.label,
        'titleIsUserSet': cassette.titleIsUserSet,
        'colorSeed': cassette.colorSeed,
        'summary': cassette.summary,
        'summaryUpdatedAt': cassette.summaryUpdatedAt?.toIso8601String(),
        'createdAt': cassette.createdAt.toIso8601String(),
        'updatedAt': cassette.updatedAt.toIso8601String(),
        'exportedAt': DateTime.now().toIso8601String(),
        'memos': [
          for (final memo in memos)
            {
              'id': memo.id,
              'createdAt': memo.createdAt.toIso8601String(),
              'durationMs': memo.durationMs,
              'language': memo.detectedLang,
              'summary': memo.memoSummary,
              'audio': audioNames[memo.id] == null
                  ? null
                  : 'audio/${audioNames[memo.id]}',
              'transcript': memo.transcript?.toJson(),
            },
        ],
      };

  static String _plainText(Transcript transcript) => transcript.segments
      .map((s) => s.words.map((w) => w.text).join(' '))
      .where((line) => line.isNotEmpty)
      .join('\n');

  static String _stamp(DateTime t) =>
      DateFormat('yyyy-MM-dd HH:mm').format(t);

  /// Keeps the label usable as a folder or archive name on every filesystem.
  static String fileSafe(String label) {
    final safe = label
        .replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1f]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return safe.isEmpty ? 'cassette' : safe;
  }

  static Future<Directory> _claimDir(Directory target, String name) async {
    for (var attempt = 0;; attempt++) {
      final suffix = attempt == 0 ? '' : ' (${attempt + 1})';
      final dir = Directory('${target.path}/$name$suffix');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        return dir;
      }
    }
  }
}
