import 'dart:math';
import 'dart:typed_data';

import 'package:diktafon/services/audio/pcm_highpass.dart';
import 'package:flutter_test/flutter_test.dart';

Float32List _tone(double hz, {double amplitude = 0.5, int seconds = 2}) {
  const rate = 16000;
  return Float32List.fromList([
    for (var i = 0; i < rate * seconds; i++)
      amplitude * sin(2 * pi * hz * i / rate),
  ]);
}

/// RMS over the second half — clear of the filter transient.
double _rms(Float32List samples) {
  var sum = 0.0;
  for (var i = samples.length ~/ 2; i < samples.length; i++) {
    sum += samples[i] * samples[i];
  }
  return sqrt(sum / (samples.length - samples.length ~/ 2));
}

void main() {
  test('speech band passes through nearly untouched', () {
    final tone = _tone(1000);
    final before = _rms(tone);
    highPassInPlace(tone);
    expect(_rms(tone), closeTo(before, before * 0.03));
  });

  test('DC offset is removed', () {
    final dc = Float32List.fromList(List.filled(16000, 0.5));
    highPassInPlace(dc);
    expect(_rms(dc), lessThan(0.001));
  });

  test('sub-speech rumble is strongly attenuated', () {
    final rumble = _tone(30);
    final before = _rms(rumble);
    highPassInPlace(rumble);
    // 2nd-order Butterworth at 80 Hz: (30/80)² ≈ 0.14 (−17 dB) at 30 Hz.
    expect(_rms(rumble), lessThan(before * 0.15),
        reason: '30 Hz should drop by ≳17 dB');
  });
}
