/// Model provisioning core (§6.6), shared by the whisper and LLM catalogs:
/// models are downloaded on demand into `<app-support>/models/…` (regenerable
/// — excluded from backup, §7.1) with streamed progress and sha256
/// verification against pinned upstream hashes (a truncated/corrupt model
/// would crash native code).
library;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'transcription_provider.dart' show ModelStatus, ProgressSink;

/// One downloadable model file, pinned by byte size + sha256.
abstract interface class ModelSpec {
  /// Stable identifier persisted in settings (e.g. 'small', 'qwen3-1.7b').
  String get tier;
  String get label;
  String get description;
  String get fileName;
  int get sizeBytes;
  String get sha256Hex;

  /// Unlisted tiers don't appear in the Settings picker unless installed
  /// (tiny models exist for tests/dev — too weak for real use, §6.6).
  bool get listed;

  Uri get url;

  /// Human size for picker rows, e.g. '181 MB' / '1.8 GB'.
  String get sizeLabel;
}

/// Snapshot of one tier for the Settings picker.
class ModelState<M extends ModelSpec> {
  const ModelState(this.model, this.status, this.progress);

  final M model;
  final ModelStatus status;

  /// Download progress in [0..1]; only meaningful while [status] is
  /// [ModelStatus.downloading].
  final double progress;
}

class ModelVerificationException implements Exception {
  const ModelVerificationException(this.message);
  final String message;

  @override
  String toString() => 'ModelVerificationException: $message';
}

/// Completes a download future aborted by [ModelManager.cancel] — callers
/// tell an intentional abort (tier switched mid-download, §5.6) from a
/// real failure and stay quiet about it.
class ModelDownloadCancelled implements Exception {
  const ModelDownloadCancelled();
}

class ModelManager<M extends ModelSpec> {
  ModelManager(
    this._dir, {
    HttpClient Function()? httpClientFactory,
    required this.catalog,
  }) : _httpClientFactory = httpClientFactory ?? HttpClient.new;

  final Directory _dir;
  final HttpClient Function() _httpClientFactory;

  /// The tiers this install knows about; tests swap in local specs.
  final List<M> catalog;

  final _changes = StreamController<void>.broadcast();
  final Map<String, double> _progress = {};
  final Map<String, Future<void>> _downloads = {};
  final Map<String, HttpClient> _clients = {};
  final Set<String> _cancelRequested = {};

  /// Emits whenever any tier's status/progress changes.
  Stream<void> get changes => _changes.stream;

  File fileOf(M model) => File('${_dir.path}/${model.fileName}');

  ModelStatus statusOf(M model) {
    if (_downloads.containsKey(model.tier)) return ModelStatus.downloading;
    return fileOf(model).existsSync()
        ? ModelStatus.ready
        : ModelStatus.notInstalled;
  }

  ModelState<M> stateOf(M model) =>
      ModelState(model, statusOf(model), _progress[model.tier] ?? 0);

  List<ModelState<M>> snapshot() =>
      [for (final model in catalog) stateOf(model)];

  /// Total disk footprint of installed models (Settings shows storage used).
  int installedBytes() => catalog
      .map((m) => fileOf(m))
      .where((f) => f.existsSync())
      .fold(0, (sum, f) => sum + f.lengthSync());

  /// Downloads and verifies a tier; concurrent calls for the same tier join
  /// the in-flight download. Progress is reported both through [onProgress]
  /// and the [changes] stream.
  Future<void> download(M model, {ProgressSink? onProgress}) {
    if (statusOf(model) == ModelStatus.ready) return Future.value();
    final inFlight = _downloads[model.tier];
    if (inFlight != null) return inFlight;

    final download = _download(model, onProgress).whenComplete(() {
      _downloads.remove(model.tier);
      _progress.remove(model.tier);
      _changes.add(null);
    });
    _downloads[model.tier] = download;
    _progress[model.tier] = 0;
    _changes.add(null);
    return download;
  }

  /// Aborts [model]'s in-flight download: its future completes with
  /// [ModelDownloadCancelled] and the partial file is removed. No-op when
  /// the tier isn't downloading.
  void cancel(M model) {
    if (!_downloads.containsKey(model.tier)) return;
    _cancelRequested.add(model.tier);
    _clients[model.tier]?.close(force: true);
  }

  /// Switch-mid-download semantics (§5.6): selecting a tier cancels every
  /// other tier still on the wire.
  void cancelExcept(String tier) {
    for (final model in catalog) {
      if (model.tier != tier) cancel(model);
    }
  }

  Future<void> _download(M model, ProgressSink? onProgress) async {
    await _dir.create(recursive: true);
    final part = File('${fileOf(model).path}.part');
    final client = _httpClientFactory();
    _clients[model.tier] = client;
    try {
      final request = await client.getUrl(model.url);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: model.url);
      }

      final sink = part.openWrite();
      var received = 0;
      final digestSink = _DigestSink();
      final hasher = sha256.startChunkedConversion(digestSink);
      try {
        await for (final chunk in response) {
          if (_cancelRequested.contains(model.tier)) {
            throw const ModelDownloadCancelled();
          }
          hasher.add(chunk);
          sink.add(chunk);
          received += chunk.length;
          final fraction = (received / model.sizeBytes).clamp(0.0, 1.0);
          _progress[model.tier] = fraction;
          onProgress?.call(fraction);
          _changes.add(null);
        }
      } finally {
        await sink.close();
      }
      hasher.close();

      if (received != model.sizeBytes ||
          digestSink.digest.toString() != model.sha256Hex) {
        throw ModelVerificationException(
            '${model.fileName}: got $received bytes, '
            'sha256 ${digestSink.digest}');
      }
      await part.rename(fileOf(model).path);
    } catch (_) {
      if (await part.exists()) await part.delete();
      // A force-closed connection surfaces as an I/O error — report the
      // cancel, not the symptom.
      if (_cancelRequested.contains(model.tier)) {
        throw const ModelDownloadCancelled();
      }
      rethrow;
    } finally {
      _cancelRequested.remove(model.tier);
      _clients.remove(model.tier);
      client.close(force: true);
    }
  }

  void delete(M model) {
    final file = fileOf(model);
    if (file.existsSync()) file.deleteSync();
    _changes.add(null);
  }

  void dispose() => _changes.close();
}

class _DigestSink implements Sink<Digest> {
  late Digest digest;

  @override
  void add(Digest data) => digest = data;

  @override
  void close() {}
}
