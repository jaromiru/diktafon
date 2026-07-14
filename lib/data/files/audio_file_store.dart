import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Audio layout (§7.1): `<app-documents>/audio/<cassetteId>/<memoId>.m4a`.
/// One file per memo; nothing is ever re-encoded or stitched on disk.
class AudioFileStore {
  AudioFileStore(this._root);

  final Directory _root;

  /// Current audio root — the anchor for rebasing paths a previous install
  /// persisted (iOS moves the data container on updates, §7.1).
  String get rootPath => _root.path;

  static Future<AudioFileStore> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory('${docs.path}/audio');
    await root.create(recursive: true);
    return AudioFileStore(root);
  }

  /// Absolute path for a memo's audio; creates the cassette dir.
  Future<String> pathFor(String cassetteId, String memoId) async {
    final dir = Directory('${_root.path}/$cassetteId');
    await dir.create(recursive: true);
    return '${dir.path}/$memoId.m4a';
  }

  Future<void> deleteMemoFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }

  Future<void> deleteCassetteDir(String cassetteId) async {
    final dir = Directory('${_root.path}/$cassetteId');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Removes audio files no memo row references (§7.1): a process killed
  /// mid-recording leaves an unfinalized capture behind — no moov atom, no
  /// DB row, invisible, unplayable, and holding space forever. Runs once at
  /// launch. Files touched after [cutoff] are spared: a capture that just
  /// started has no row *yet*, and a mid-copy import file gets its row
  /// moments later.
  Future<int> sweepOrphans(
    bool Function(String memoId) isReferenced, {
    required DateTime cutoff,
  }) async {
    if (!await _root.exists()) return 0;
    var removed = 0;
    await for (final entry in _root.list(recursive: true)) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      final dot = name.lastIndexOf('.');
      final stem = dot > 0 ? name.substring(0, dot) : name;
      if (isReferenced(stem)) continue;
      try {
        if (!entry.lastModifiedSync().isBefore(cutoff)) continue;
        entry.deleteSync();
        removed++;
      } catch (_) {
        // Best-effort hygiene — a locked/vanished file is not a problem.
      }
    }
    return removed;
  }
}
