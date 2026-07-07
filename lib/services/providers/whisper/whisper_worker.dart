/// The whisper worker isolate (§6.5): all FFI inference runs here so the UI
/// isolate never blocks. The isolate is long-lived and keeps the loaded
/// whisper context warm between jobs (model load costs seconds; queue
/// concurrency is 1, so one context is enough).
///
/// PCM is handed over as a *file path* (raw f32le, 16 kHz mono — what the
/// PcmDecoder writes), not as a message payload, to avoid copying tens of MB
/// across isolates for long memos.
library;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';

import '../../../domain/models.dart';
import 'whisper_bindings.dart';
import 'word_timing.dart';

class WhisperWorkerException implements Exception {
  const WhisperWorkerException(this.message);
  final String message;

  @override
  String toString() => 'WhisperWorkerException: $message';
}

class WhisperWorker {
  WhisperWorker(this._libraryPath);

  final String _libraryPath;

  Isolate? _isolate;
  SendPort? _commands;
  StreamSubscription<dynamic>? _subscription;
  final Map<int, Completer<Map<dynamic, dynamic>>> _inFlight = {};
  int _nextRequestId = 0;
  Future<void>? _spawning;

  Future<void> _ensureSpawned() {
    return _spawning ??= () async {
      final replies = ReceivePort();
      final ready = Completer<SendPort>();
      _subscription = replies.listen((message) {
        if (message is SendPort) {
          ready.complete(message);
          return;
        }
        final response = message as Map<dynamic, dynamic>;
        _inFlight.remove(response['id'])?.complete(response);
      });
      _isolate = await Isolate.spawn(
        _workerMain,
        [replies.sendPort, _libraryPath],
        debugName: 'whisper-worker',
      );
      _commands = await ready.future;
    }();
  }

  /// Transcribes the raw PCM file; [cancelFlagAddress] is a caller-owned
  /// native int32 polled by the engine (non-zero aborts).
  Future<Transcript> transcribe({
    required String modelPath,
    required String pcmPath,
    String? languageCode,
    required int cancelFlagAddress,
    required int threads,
  }) async {
    await _ensureSpawned();
    final id = _nextRequestId++;
    final completer = Completer<Map<dynamic, dynamic>>();
    _inFlight[id] = completer;
    _commands!.send({
      'id': id,
      'model': modelPath,
      'pcm': pcmPath,
      'lang': languageCode,
      'cancel': cancelFlagAddress,
      'threads': threads,
    });
    final response = await completer.future;
    final error = response['error'];
    if (error != null) throw WhisperWorkerException(error as String);
    return Transcript.fromJson(
        (response['transcript'] as Map).cast<String, dynamic>());
  }

  Future<void> dispose() async {
    _spawning = null;
    _commands?.send(const {'id': -1, 'close': true});
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _commands = null;
    await _subscription?.cancel();
    for (final pending in _inFlight.values) {
      pending.completeError(const WhisperWorkerException('worker disposed'));
    }
    _inFlight.clear();
  }
}

// ————— isolate side —————

void _workerMain(List<Object> args) {
  final replyTo = args[0] as SendPort;
  final libraryPath = args[1] as String;

  final commands = ReceivePort();
  replyTo.send(commands.sendPort);

  WhisperBindings? bindings;
  Pointer<Void> context = nullptr;
  var loadedModelPath = '';

  commands.listen((message) {
    final request = message as Map<dynamic, dynamic>;
    if (request['close'] == true) {
      if (context != nullptr) bindings?.free(context);
      commands.close();
      return;
    }
    final id = request['id'] as int;
    try {
      bindings ??= WhisperBindings.open(libraryPath);
      final modelPath = request['model'] as String;
      if (context == nullptr || loadedModelPath != modelPath) {
        if (context != nullptr) bindings!.free(context);
        context = _initContext(bindings!, modelPath);
        loadedModelPath = modelPath;
      }
      final transcript = _transcribeFile(
        bindings!,
        context,
        pcmPath: request['pcm'] as String,
        languageCode: request['lang'] as String?,
        cancelFlagAddress: request['cancel'] as int,
        threads: request['threads'] as int,
      );
      replyTo.send({'id': id, 'transcript': transcript.toJson()});
    } catch (e) {
      replyTo.send({'id': id, 'error': e.toString()});
    }
  });
}

Pointer<Void> _initContext(WhisperBindings bindings, String modelPath) {
  final pathC = modelPath.toNativeUtf8();
  try {
    final context = bindings.init(pathC);
    if (context == nullptr) {
      throw WhisperWorkerException('failed to load model at $modelPath');
    }
    return context;
  } finally {
    calloc.free(pathC);
  }
}

Transcript _transcribeFile(
  WhisperBindings bindings,
  Pointer<Void> context, {
  required String pcmPath,
  required String? languageCode,
  required int cancelFlagAddress,
  required int threads,
}) {
  final bytes = File(pcmPath).readAsBytesSync();
  final pcm = bytes.buffer.asFloat32List(0, bytes.lengthInBytes ~/ 4);

  // whisper.cpp rejects sub-second inputs; pad short memos with silence.
  const sampleRate = 16000;
  final sampleCount = max(pcm.length, sampleRate * 3 ~/ 2);

  final pcmC = calloc<Float>(sampleCount);
  final langC = languageCode?.toNativeUtf8() ?? nullptr;
  try {
    pcmC.asTypedList(sampleCount).setRange(0, pcm.length, pcm);
    final ret = bindings.transcribe(
      context,
      pcmC,
      sampleCount,
      langC,
      threads,
      Pointer<Int32>.fromAddress(cancelFlagAddress),
    );
    if (ret != 0) {
      // Also the abort path — the provider maps it back to "cancelled" by
      // checking its own token.
      throw WhisperWorkerException('whisper_full failed (code $ret)');
    }
    return assembleTranscript(
      bindings.lang(context).toDartString(),
      _readSegments(bindings, context),
    );
  } finally {
    calloc.free(pcmC);
    if (langC != nullptr) calloc.free(langC);
  }
}

List<RawSegment> _readSegments(WhisperBindings bindings, Pointer<Void> ctx) {
  final segments = <RawSegment>[];
  final segmentCount = bindings.nSegments(ctx);
  for (var i = 0; i < segmentCount; i++) {
    final tokens = <RawToken>[];
    final tokenCount = bindings.nTokens(ctx, i);
    for (var j = 0; j < tokenCount; j++) {
      if (bindings.tokenIsText(ctx, i, j) == 0) continue;
      tokens.add(RawToken(
        copyCStringBytes(bindings.tokenText(ctx, i, j)),
        bindings.tokenT0Ms(ctx, i, j),
        bindings.tokenT1Ms(ctx, i, j),
      ));
    }
    segments.add(RawSegment(
      bindings.segmentT0Ms(ctx, i),
      bindings.segmentT1Ms(ctx, i),
      tokens,
    ));
  }
  return segments;
}
