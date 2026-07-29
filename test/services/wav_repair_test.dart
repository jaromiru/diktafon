import 'dart:io';
import 'dart:typed_data';

import 'package:diktafon/services/audio/wav_repair.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a 16 kHz mono s16 PCM WAV. [riffSize]/[dataSize] default to the
/// correct values; tests pass stale ones to mimic an interrupted recorder.
Uint8List buildWav(int dataBytes,
    {int? riffSize, int? dataSize, List<int> preDataChunk = const []}) {
  final data = BytesBuilder();
  void str(String s) => data.add(s.codeUnits);
  void u32(int v) =>
      data.add(Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little));
  void u16(int v) =>
      data.add(Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little));

  final total = 4 + // WAVE
      24 + // fmt
      preDataChunk.length +
      8 +
      dataBytes;
  str('RIFF');
  u32(riffSize ?? total);
  str('WAVE');
  str('fmt ');
  u32(16);
  u16(1); // PCM
  u16(1); // mono
  u32(16000);
  u32(32000); // byte rate
  u16(2); // block align
  u16(16); // bits
  data.add(preDataChunk);
  str('data');
  u32(dataSize ?? dataBytes);
  data.add(Uint8List(dataBytes)); // silence — content is irrelevant here
  return data.toBytes();
}

void main() {
  late Directory work;

  setUp(() => work = Directory.systemTemp.createTempSync('dk_wav_'));
  tearDown(() => work.deleteSync(recursive: true));

  Future<String> write(Uint8List bytes) async {
    final path = '${work.path}/probe.wav';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<(int, int)> readSizes(String path) async {
    final bytes = await File(path).readAsBytes();
    final view = ByteData.sublistView(bytes);
    // Canonical layout in these fixtures: data chunk header at byte 36.
    return (view.getUint32(4, Endian.little), view.getUint32(40, Endian.little));
  }

  test('stale zero sizes (killed capture) are patched from the file length',
      () async {
    final path = await write(buildWav(32000, riffSize: 0, dataSize: 0));
    final info = await repairWav(path);
    expect(info, isNotNull);
    expect(info!.dataBytes, 32000);
    expect(info.durationMs, 1000); // 32 KB at 32 KB/s
    final (riff, data) = await readSizes(path);
    expect(riff, 36 + 32000);
    expect(data, 32000);
  });

  test('0xFFFFFFFF placeholder sizes are patched too', () async {
    final path = await write(
        buildWav(16000, riffSize: 0xFFFFFFFF, dataSize: 0xFFFFFFFF));
    final info = await repairWav(path);
    expect(info!.durationMs, 500);
    final (riff, data) = await readSizes(path);
    expect(riff, 36 + 16000);
    expect(data, 16000);
  });

  test('a correctly finalized file is left byte-identical', () async {
    final path = await write(buildWav(8000));
    final before = await File(path).readAsBytes();
    final info = await repairWav(path);
    expect(info!.durationMs, 250);
    expect(await File(path).readAsBytes(), before);
  });

  test('extra chunk between fmt and data is walked over', () async {
    final list = BytesBuilder();
    list.add('LIST'.codeUnits);
    list.add(Uint8List(4)..buffer.asByteData().setUint32(0, 4, Endian.little));
    list.add('INFO'.codeUnits);
    final path = await write(
        buildWav(6400, dataSize: 0, preDataChunk: list.toBytes()));
    final info = await repairWav(path);
    expect(info!.durationMs, 200);
  });

  test('non-WAV and truncated files are rejected', () async {
    expect(await repairWav('${work.path}/absent.wav'), isNull);

    final garbage = '${work.path}/garbage.wav';
    await File(garbage).writeAsBytes(List.filled(4096, 42));
    expect(await repairWav(garbage), isNull);

    final stub = '${work.path}/stub.wav';
    await File(stub).writeAsBytes(buildWav(0).sublist(0, 40));
    expect(await repairWav(stub), isNull);
  });

  test('header-only file (no samples yet) is rejected', () async {
    final path = await write(buildWav(0, riffSize: 0, dataSize: 0));
    expect(await repairWav(path), isNull);
  });
}
