/// The llama worker isolate (§6.5): all LLM inference runs here so the UI
/// isolate never blocks. Long-lived, keeps the loaded model context warm
/// between jobs (model load costs seconds; queue concurrency is 1, so one
/// context is enough). Mirrors WhisperWorker.
library;

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'llama_bindings.dart';

class LlamaWorkerException implements Exception {
  const LlamaWorkerException(this.message);
  final String message;

  @override
  String toString() => 'LlamaWorkerException: $message';
}

class LlamaWorker {
  LlamaWorker(this._libraryPath);

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
        debugName: 'llama-worker',
      );
      _commands = await ready.future;
    }();
  }

  /// Runs one [system, user] exchange; [cancelFlagAddress] is a caller-owned
  /// native int32 polled by the engine (non-zero aborts). Returns the raw
  /// completion — the provider post-processes it.
  Future<String> generate({
    required String modelPath,
    required int contextTokens,
    required String system,
    required String user,
    required int maxTokens,
    required double temperature,
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
      'nCtx': contextTokens,
      'system': system,
      'user': user,
      'maxTokens': maxTokens,
      'temperature': temperature,
      'cancel': cancelFlagAddress,
      'threads': threads,
    });
    final response = await completer.future;
    final error = response['error'];
    if (error != null) throw LlamaWorkerException(error as String);
    return response['text'] as String;
  }

  Future<void> dispose() async {
    _spawning = null;
    _commands?.send(const {'id': -1, 'close': true});
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _commands = null;
    await _subscription?.cancel();
    for (final pending in _inFlight.values) {
      pending.completeError(const LlamaWorkerException('worker disposed'));
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

  LlamaBindings? bindings;
  Pointer<Void> context = nullptr;
  var loadedModelPath = '';
  var loadedCtxTokens = 0;

  commands.listen((message) {
    final request = message as Map<dynamic, dynamic>;
    if (request['close'] == true) {
      if (context != nullptr) bindings?.free(context);
      commands.close();
      return;
    }
    final id = request['id'] as int;
    try {
      bindings ??= LlamaBindings.open(libraryPath);
      final modelPath = request['model'] as String;
      final nCtx = request['nCtx'] as int;
      if (context == nullptr ||
          loadedModelPath != modelPath ||
          loadedCtxTokens != nCtx) {
        if (context != nullptr) bindings!.free(context);
        context = _initContext(bindings!, modelPath, nCtx,
            threads: request['threads'] as int);
        loadedModelPath = modelPath;
        loadedCtxTokens = nCtx;
      }
      final text = _generate(
        bindings!,
        context,
        system: request['system'] as String,
        user: request['user'] as String,
        maxTokens: request['maxTokens'] as int,
        temperature: request['temperature'] as double,
        cancelFlagAddress: request['cancel'] as int,
      );
      replyTo.send({'id': id, 'text': text});
    } catch (e) {
      replyTo.send({'id': id, 'error': e.toString()});
    }
  });
}

Pointer<Void> _initContext(
  LlamaBindings bindings,
  String modelPath,
  int nCtx, {
  required int threads,
}) {
  final pathC = modelPath.toNativeUtf8();
  try {
    final context = bindings.init(pathC, nCtx, threads);
    if (context == nullptr) {
      throw LlamaWorkerException('failed to load model at $modelPath');
    }
    return context;
  } finally {
    calloc.free(pathC);
  }
}

String _generate(
  LlamaBindings bindings,
  Pointer<Void> context, {
  required String system,
  required String user,
  required int maxTokens,
  required double temperature,
  required int cancelFlagAddress,
}) {
  final systemC = system.toNativeUtf8();
  final userC = user.toNativeUtf8();
  try {
    final ret = bindings.generate(
      context,
      systemC,
      userC,
      maxTokens,
      temperature,
      Pointer<Int32>.fromAddress(cancelFlagAddress),
    );
    if (ret != 0) {
      // -3 (prompt too long) should never happen — the provider truncates
      // input to the context budget beforehand.
      throw LlamaWorkerException('dk_llama_generate failed (code $ret)');
    }
    // Also the abort path — the provider maps an empty/partial result back
    // to "cancelled" by checking its own token.
    return bindings.result(context).toDartString();
  } finally {
    calloc.free(systemC);
    calloc.free(userC);
  }
}
