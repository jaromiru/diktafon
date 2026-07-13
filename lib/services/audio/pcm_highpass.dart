/// High-pass filter on the transcription path
/// (docs/features/noise-robust-transcription.md §3.6/phase 1.4): removes
/// wind rumble and handling noise below the speech band (fundamentals sit
/// above ~85 Hz) from the PCM whisper sees. Runs on the decoded `.f32`
/// file, after the platform decoder and before the worker isolate — the
/// stored recording is never altered (§3.8: originals stay the source of
/// truth). Pure Dart, so every platform gets the identical filter.
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Applies [highPassInPlace] over a raw f32le 16 kHz mono PCM file.
Future<void> highPassPcmFile(
  String path, {
  double cutoffHz = 80,
  int sampleRate = 16000,
}) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  final samples = bytes.buffer.asFloat32List(0, bytes.lengthInBytes ~/ 4);
  highPassInPlace(samples, cutoffHz: cutoffHz, sampleRate: sampleRate);
  await file.writeAsBytes(bytes, flush: true);
}

/// Second-order Butterworth high-pass (RBJ audio-EQ biquad, Q = 1/√2),
/// causal single pass — the same shape a live capture path would use.
void highPassInPlace(
  Float32List samples, {
  double cutoffHz = 80,
  int sampleRate = 16000,
}) {
  final w0 = 2 * pi * cutoffHz / sampleRate;
  final alpha = sin(w0) / (2 * (1 / sqrt2));
  final cosW0 = cos(w0);
  final a0 = 1 + alpha;
  final b0 = (1 + cosW0) / 2 / a0;
  final b1 = -(1 + cosW0) / a0;
  final b2 = (1 + cosW0) / 2 / a0;
  final a1 = -2 * cosW0 / a0;
  final a2 = (1 - alpha) / a0;

  // Direct form II transposed.
  var z1 = 0.0, z2 = 0.0;
  for (var i = 0; i < samples.length; i++) {
    final x = samples[i];
    final y = b0 * x + z1;
    z1 = b1 * x - a1 * y + z2;
    z2 = b2 * x - a2 * y;
    samples[i] = y;
  }
}
