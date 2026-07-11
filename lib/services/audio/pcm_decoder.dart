/// Decoding memo audio (AAC `.m4a`, §6.4) into what whisper.cpp eats:
/// raw float32 little-endian PCM, 16 kHz mono, written to a file (the worker
/// isolate reads it back — no multi-MB isolate messages).
library;

import 'dart:io';

import 'package:flutter/services.dart';

abstract interface class PcmDecoder {
  /// Decodes [audioPath] to raw f32le 16 kHz mono PCM at [pcmPath].
  Future<void> decodeToF32(String audioPath, String pcmPath);
}

/// Picks the platform decoder: the host-app codec channel on mobile
/// (MediaCodec on Android, AVAssetReader on iOS), ffmpeg CLI elsewhere
/// (the Linux dev/E2E box already depends on ffmpeg for recording).
PcmDecoder defaultPcmDecoder() => Platform.isAndroid || Platform.isIOS
    ? HostCodecPcmDecoder()
    : FfmpegPcmDecoder();

class FfmpegPcmDecoder implements PcmDecoder {
  @override
  Future<void> decodeToF32(String audioPath, String pcmPath) async {
    final result = await Process.run('ffmpeg', [
      '-y',
      '-v', 'error',
      '-i', audioPath,
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
}

/// Mobile: the host app decodes with its platform codec — MediaExtractor +
/// MediaCodec on Android (android/…/MainActivity.kt), AVAssetReader on iOS
/// (ios/Runner/AppDelegate.swift) — reached over a method channel.
class HostCodecPcmDecoder implements PcmDecoder {
  static const _channel = MethodChannel('diktafon/pcm_decoder');

  @override
  Future<void> decodeToF32(String audioPath, String pcmPath) =>
      _channel.invokeMethod<void>('decodeToF32', {
        'input': audioPath,
        'output': pcmPath,
      });
}
