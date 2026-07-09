/// Cassette import (§8, data portability): the counterpart of
/// `CassetteExporter`. Reads a `.zip` archive (or an already-extracted
/// export folder), and adds its cassettes to the library as new ones —
/// nothing existing is touched, importing twice yields duplicates (D14).
/// Fresh ids are drawn for everything: the archive's ids may collide with
/// rows on this device (restore-after-reinstall, re-import).
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:uuid/uuid.dart';

import '../../data/files/audio_file_store.dart';
import '../../data/repositories/cassette_repository.dart';
import '../../data/repositories/memo_repository.dart';
import '../../domain/models.dart';
import '../export/cassette_exporter.dart';

/// What an import run did; one archive may hold many cassettes and any of
/// them can fail independently (corrupt manifest, disk full) without
/// sinking the rest.
class ImportResult {
  const ImportResult({
    required this.cassettes,
    required this.memos,
    required this.reEnqueued,
    required this.skippedMemos,
    required this.failures,
  });

  /// Cassettes and memos actually inserted.
  final int cassettes;
  final int memos;

  /// Memos sent back through the job pipeline because the archive lacked
  /// their transcript or gist.
  final int reEnqueued;

  /// Memo entries with neither audio nor transcript — empty shells with
  /// nothing to restore.
  final int skippedMemos;

  /// One human-readable line per cassette folder that could not be
  /// imported (its partial rows and files are rolled back).
  final List<String> failures;

  /// Nothing recognizable in the archive at all.
  bool get isEmpty => cassettes == 0 && failures.isEmpty;
}

class CassetteImporter {
  CassetteImporter({
    required this._cassettes,
    required this._memos,
    required this._files,
    required this._enqueueTranscription,
    required this._retryEnrichment,
  });

  final CassetteRepository _cassettes;
  final MemoRepository _memos;
  final AudioFileStore _files;

  /// Job-queue seams (kept as functions so tests don't need a real queue):
  /// wired to `JobQueue.enqueueTranscription` / `retryEnrichment`.
  final Future<void> Function(String memoId) _enqueueTranscription;
  final Future<void> Function(String memoId) _retryEnrichment;

  final _uuid = const Uuid();

  /// Extracts [zip] to a temp folder and imports every cassette found.
  /// Extraction is zip-slip-safe (`extractFileToDisk` skips entries that
  /// would land outside the target).
  Future<ImportResult> importArchive(File zip) async {
    final staging = await Directory.systemTemp.createTemp('diktafon_import_');
    try {
      await extractFileToDisk(zip.path, staging.path);
      return await importDirectory(staging);
    } finally {
      await staging.delete(recursive: true);
    }
  }

  /// Accepts either a single export folder (`cassette.json` at its root) or
  /// a folder of them — "export all" writes one folder per cassette.
  Future<ImportResult> importDirectory(Directory root) async {
    var cassettes = 0, memos = 0, reEnqueued = 0, skipped = 0;
    final failures = <String>[];
    for (final manifest in _findManifests(root)) {
      try {
        final counts = await _importOne(manifest);
        cassettes++;
        memos += counts.memos;
        reEnqueued += counts.reEnqueued;
        skipped += counts.skippedMemos;
      } catch (e) {
        failures.add('${_folderName(root, manifest)}: $e');
      }
    }
    return ImportResult(
      cassettes: cassettes,
      memos: memos,
      reEnqueued: reEnqueued,
      skippedMemos: skipped,
      failures: failures,
    );
  }

  List<File> _findManifests(Directory root) {
    final own = File('${root.path}/cassette.json');
    if (own.existsSync()) return [own];
    final found = <File>[];
    for (final entry in root.listSync()..sort((a, b) => a.path.compareTo(b.path))) {
      if (entry is! Directory) continue;
      final manifest = File('${entry.path}/cassette.json');
      if (manifest.existsSync()) found.add(manifest);
    }
    return found;
  }

  Future<({int memos, int reEnqueued, int skippedMemos})> _importOne(
      File manifestFile) async {
    final dir = manifestFile.parent;
    final json =
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
    final version = (json['formatVersion'] as num?)?.toInt() ?? 0;
    if (version > CassetteExporter.manifestVersion) {
      throw FormatException(
          'archive written by a newer app (format $version)');
    }

    final label = json['label'] as String?;
    final cassette = await _cassettes.insertImported(
      label: label,
      // Pre-versioned manifests lack the flag; a labeled import must never
      // be renamed by the auto-suggester (D10), so a label implies user-set.
      titleIsUserSet: json['titleIsUserSet'] as bool? ?? label != null,
      colorSeed: (json['colorSeed'] as num?)?.toInt(),
      summary: json['summary'] as String?,
      summaryUpdatedAt: _date(json['summaryUpdatedAt']),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
    );

    try {
      var imported = 0, skipped = 0;
      // Jobs fire only once the whole cassette is in — a failure mid-way
      // rolls back the rows, and jobs must not point at deleted memos.
      final needTranscription = <String>[];
      final needEnrichment = <String>[];

      for (final entry in json['memos'] as List? ?? const []) {
        final m = entry as Map<String, dynamic>;
        final audio = _audioSource(dir, m['audio'] as String?);
        final transcript = _transcript(m['transcript']);
        if (audio == null && transcript == null) {
          skipped++; // empty shell — nothing to restore
          continue;
        }

        final memoId = _uuid.v4();
        final path = await _files.pathFor(cassette.id, memoId);
        // Audio-less memos keep their (dead) canonical path — the same
        // state the app already tolerates after a metadata-only OS restore.
        if (audio != null) await audio.copy(path);

        final gist = m['summary'] as String?;
        await _memos.insert(Memo(
          id: memoId,
          cassetteId: cassette.id,
          filePath: path,
          durationMs: (m['durationMs'] as num?)?.toInt() ?? 0,
          createdAt: _date(m['createdAt']) ?? DateTime.now(),
          status: transcript == null
              ? MemoStatus.stored
              : gist == null
                  ? MemoStatus.transcribed
                  : MemoStatus.ready,
          detectedLang: m['language'] as String?,
          transcript: transcript,
          memoSummary: gist,
        ));
        imported++;

        if (transcript == null) {
          needTranscription.add(memoId); // audio exists — shells skipped above
        } else if (gist == null) {
          needEnrichment.add(memoId);
        }
      }

      for (final id in needTranscription) {
        await _enqueueTranscription(id);
      }
      for (final id in needEnrichment) {
        await _retryEnrichment(id);
      }
      return (
        memos: imported,
        reEnqueued: needTranscription.length + needEnrichment.length,
        skippedMemos: skipped,
      );
    } catch (_) {
      // Half a cassette helps nobody: drop the rows and copied audio, then
      // let the caller report the failure.
      await _cassettes.delete(cassette.id);
      await _files.deleteCassetteDir(cassette.id);
      rethrow;
    }
  }

  /// The manifest's audio paths are relative (`audio/<name>`); anything
  /// absolute or escaping the export folder is treated as absent — the
  /// memo still imports with its transcript.
  File? _audioSource(Directory dir, String? relative) {
    if (relative == null || _escapes(relative)) return null;
    final file = File('${dir.path}/$relative');
    return file.existsSync() ? file : null;
  }

  static bool _escapes(String relative) =>
      relative.startsWith('/') ||
      relative.split(RegExp(r'[/\\]')).contains('..');

  /// A malformed transcript degrades to "not transcribed" (the memo is
  /// re-enqueued for transcription if its audio survived).
  static Transcript? _transcript(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return Transcript.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _date(Object? iso) =>
      iso is String ? DateTime.tryParse(iso) : null;

  static String _folderName(Directory root, File manifest) {
    final parent = manifest.parent.path;
    return parent == root.path
        ? root.path.split(Platform.pathSeparator).last
        : parent.split(Platform.pathSeparator).last;
  }
}
