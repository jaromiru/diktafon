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
}
