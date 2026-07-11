/// Pure-Dart tone fixtures: the tests need real audio files the tape player
/// can load, and spawning ffmpeg is impossible on iOS (`Process.run` is
/// unsupported), so tones are synthesized in-process. WAV is also
/// sample-exact — no AAC priming-frame padding to skew memo boundaries.
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// Minimal RIFF/WAVE writer: [seconds] of a [hz] sine, 16-bit PCM mono.
Uint8List toneWav({required int hz, required int seconds, int rate = 44100}) {
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
