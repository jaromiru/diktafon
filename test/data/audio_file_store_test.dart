import 'dart:io';

import 'package:diktafon/data/files/audio_file_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// §7.1 launch sweep: audio files no memo row references (a capture killed
/// before stop() ever inserted its row) are removed — but never anything
/// fresh enough to still be getting its row.
void main() {
  late Directory root;
  late AudioFileStore store;
  final past = DateTime.now().subtract(const Duration(hours: 2));

  setUp(() {
    root = Directory.systemTemp.createTempSync('dk_store_test_');
    store = AudioFileStore(root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<File> put(String cassetteId, String memoId,
      {bool old = true}) async {
    final file = File(await store.pathFor(cassetteId, memoId))
      ..writeAsStringSync('audio');
    if (old) file.setLastModifiedSync(past);
    return file;
  }

  test('unreferenced old files go, referenced ones stay', () async {
    final live = await put('c1', 'memo-live');
    final orphan = await put('c1', 'memo-orphan');
    final removed = await store.sweepOrphans(
      {'memo-live'}.contains,
      cutoff: DateTime.now().subtract(const Duration(hours: 1)),
    );

    expect(removed, 1);
    expect(live.existsSync(), isTrue);
    expect(orphan.existsSync(), isFalse);
  });

  test('a fresh orphan is spared — it may be a capture that just started',
      () async {
    final fresh = await put('c1', 'memo-inflight', old: false);
    final removed = await store.sweepOrphans(
      (_) => false,
      cutoff: DateTime.now().subtract(const Duration(hours: 1)),
    );

    expect(removed, 0);
    expect(fresh.existsSync(), isTrue);
  });

  test('an empty or missing root is a no-op', () async {
    expect(
        await store.sweepOrphans((_) => true, cutoff: DateTime.now()), 0);
    root.deleteSync(recursive: true);
    expect(
        await store.sweepOrphans((_) => true, cutoff: DateTime.now()), 0);
    root.createSync(); // for tearDown
  });
}
