/// Encoding a finished capture (PCM WAV, §6.4) into its final archival form:
/// mono AAC-LC `.m4a`, ~48 kbps. Capture stays WAV on disk until this runs so
/// a process death never strands an unplayable file (D13/§14); the transcode
/// job swaps the memo over once the encode has landed.
library;

import 'dart:io';

import 'package:flutter/services.dart';

abstract interface class AudioTranscoder {
  /// Encodes the PCM WAV at [wavPath] to AAC-LC `.m4a` at [outPath].
  Future<void> transcode(String wavPath, String outPath);
}

/// Picks the platform encoder: the host-app codec channel on mobile
/// (MediaCodec + MediaMuxer on Android, AVAssetWriter on iOS), ffmpeg CLI
/// elsewhere (the Linux dev/E2E box already depends on ffmpeg for capture).
AudioTranscoder defaultAudioTranscoder() => Platform.isAndroid || Platform.isIOS
    ? HostCodecAudioTranscoder()
    : FfmpegAudioTranscoder();

class FfmpegAudioTranscoder implements AudioTranscoder {
  @override
  Future<void> transcode(String wavPath, String outPath) async {
    final result = await Process.run('ffmpeg', [
      '-y',
      '-v', 'error',
      '-i', wavPath,
      '-c:a', 'aac',
      '-b:a', '48k',
      '-movflags', '+faststart',
      outPath,
    ]);
    if (result.exitCode != 0) {
      throw ProcessException(
          'ffmpeg', const [], result.stderr.toString(), result.exitCode);
    }
  }
}

/// Mobile: the host app encodes with its platform codec — MediaCodec +
/// MediaMuxer on Android (android/…/MainActivity.kt), AVAssetReader +
/// AVAssetWriter on iOS (ios/Runner/AppDelegate.swift) — reached over a
/// method channel.
class HostCodecAudioTranscoder implements AudioTranscoder {
  static const _channel = MethodChannel('diktafon/transcoder');

  @override
  Future<void> transcode(String wavPath, String outPath) =>
      _channel.invokeMethod<void>('transcodeToAac', {
        'input': wavPath,
        'output': outPath,
        'bitRate': 48000,
      });
}
