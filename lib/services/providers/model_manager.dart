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
  /// [ModelStatus.downloading] or [ModelStatus.paused] (the fraction already
  /// on disk).
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

/// Completes a download future halted by [ModelManager.pause]: the partial
/// is stashed on disk (`.paused`) and a later [ModelManager.download] picks
/// it back up. Unlike a plain interruption, a stashed pause is *not*
/// auto-resumed at startup — the user chose to stop (metered connection).
class ModelDownloadPaused implements Exception {
  const ModelDownloadPaused();
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
  final Set<String> _pauseRequested = {};

  /// Emits whenever any tier's status/progress changes.
  Stream<void> get changes => _changes.stream;

  File fileOf(M model) => File('${_dir.path}/${model.fileName}');

  /// The in-flight partial: interrupted attempts leave it for resume.
  File _partFileOf(M model) => File('${fileOf(model).path}.part');

  /// A partial stashed by [pause] — kept out of `.part` so a restart's
  /// [resumeInterrupted] leaves it alone.
  File _pausedFileOf(M model) => File('${fileOf(model).path}.paused');

  ModelStatus statusOf(M model) {
    if (_downloads.containsKey(model.tier)) return ModelStatus.downloading;
    if (fileOf(model).existsSync()) return ModelStatus.ready;
    if (_partFileOf(model).existsSync() || _pausedFileOf(model).existsSync()) {
      return ModelStatus.paused;
    }
    return ModelStatus.notInstalled;
  }

  ModelState<M> stateOf(M model) {
    final status = statusOf(model);
    return ModelState(model, status, switch (status) {
      ModelStatus.downloading => _progress[model.tier] ?? 0,
      ModelStatus.paused => _partialFraction(model),
      _ => 0,
    });
  }

  double _partialFraction(M model) {
    for (final file in [_partFileOf(model), _pausedFileOf(model)]) {
      if (file.existsSync()) {
        return (file.lengthSync() / model.sizeBytes).clamp(0.0, 1.0);
      }
    }
    return 0;
  }

  List<ModelState<M>> snapshot() =>
      [for (final model in catalog) stateOf(model)];

  /// Total disk footprint of installed models (Settings shows storage used).
  int installedBytes() => catalog
      .map((m) => fileOf(m))
      .where((f) => f.existsSync())
      .fold(0, (sum, f) => sum + f.lengthSync());

  /// Downloads and verifies a tier; concurrent calls for the same tier join
  /// the in-flight download. Progress is reported both through [onProgress]
  /// and the [changes] stream. A partial file left by an interrupted attempt
  /// is resumed with an HTTP Range request, not thrown away.
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
    // A resume already has bytes on disk — start the visible progress there,
    // not at 0 % (re-hashing a big partial takes a while and the bar would
    // sit wrong the whole time).
    _progress[model.tier] = _partialFraction(model);
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

  /// Halts [model]'s in-flight download but keeps its bytes: the future
  /// completes with [ModelDownloadPaused], the partial is stashed as
  /// `.paused` (status [ModelStatus.paused]) and a later [download] resumes
  /// it. No-op when the tier isn't downloading.
  void pause(M model) {
    if (!_downloads.containsKey(model.tier)) return;
    _pauseRequested.add(model.tier);
    _clients[model.tier]?.close(force: true);
  }

  /// Puts downloads that were interrupted mid-flight (app force-closed,
  /// crash, network drop) back on the wire: any tier with a `.part` on disk.
  /// Explicitly paused tiers (`.paused`) stay put until the user resumes
  /// them. Failures are quiet — the tier shows as paused in Settings and a
  /// tap retries. Completes when every resumed download settles; true when
  /// at least one model landed (callers drain parked jobs then).
  Future<bool> resumeInterrupted() async {
    var landed = false;
    await Future.wait([
      for (final model in catalog)
        if (statusOf(model) == ModelStatus.paused &&
            _partFileOf(model).existsSync())
          download(model).then<void>((_) {
            landed = true;
          }).catchError((_) {}),
    ]);
    return landed;
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
    final part = _partFileOf(model);
    final paused = _pausedFileOf(model);
    final client = _httpClientFactory();
    _clients[model.tier] = client;
    try {
      // A stashed pause resumes exactly like an interruption — move it back
      // into the live partial slot ('.part' wins if both somehow exist).
      if (await paused.exists()) {
        await part.exists()
            ? await paused.delete()
            : await paused.rename(part.path);
      }

      // An interrupted attempt (network drop, app killed mid-download) left
      // a partial file behind — ask the server for just the rest.
      var existing = 0;
      if (await part.exists()) {
        final length = await part.length();
        if (length > 0 && length < model.sizeBytes) existing = length;
      }

      final request = await client.getUrl(model.url);
      if (existing > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existing-');
      }
      final response = await request.close();
      final resumed = existing > 0 &&
          response.statusCode == HttpStatus.partialContent;
      if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable) {
        // The remote file no longer matches the partial — start over.
        await part.delete();
        throw HttpException('HTTP ${response.statusCode}', uri: model.url);
      }
      if (response.statusCode != HttpStatus.ok && !resumed) {
        throw HttpException('HTTP ${response.statusCode}', uri: model.url);
      }

      var received = 0;
      final digestSink = _DigestSink();
      final hasher = sha256.startChunkedConversion(digestSink);
      if (resumed) {
        // The pinned sha256 covers the whole file — feed the bytes already
        // on disk through the hasher before appending the new ones.
        await for (final chunk in part.openRead()) {
          if (_cancelRequested.contains(model.tier)) {
            throw const ModelDownloadCancelled();
          }
          if (_pauseRequested.contains(model.tier)) {
            throw const ModelDownloadPaused();
          }
          hasher.add(chunk);
        }
        received = existing;
        final fraction = (received / model.sizeBytes).clamp(0.0, 1.0);
        _progress[model.tier] = fraction;
        onProgress?.call(fraction);
        _changes.add(null);
      }

      final sink =
          part.openWrite(mode: resumed ? FileMode.append : FileMode.write);
      try {
        await for (final chunk in response) {
          if (_cancelRequested.contains(model.tier)) {
            throw const ModelDownloadCancelled();
          }
          if (_pauseRequested.contains(model.tier)) {
            throw const ModelDownloadPaused();
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
    } catch (e) {
      // Proven-bad bytes and explicit aborts drop the partial file; a pause
      // stashes it; a transient failure keeps it so the next attempt
      // resumes. Cancel wins over pause when both raced in (tier switch
      // right after a pause).
      final cancelled = _cancelRequested.contains(model.tier);
      final pausedNow = !cancelled && _pauseRequested.contains(model.tier);
      if ((cancelled || e is ModelVerificationException) &&
          await part.exists()) {
        await part.delete();
      } else if (pausedNow && await part.exists()) {
        await part.rename(paused.path);
      }
      // A force-closed connection surfaces as an I/O error — report the
      // cancel/pause, not the symptom.
      if (cancelled) throw const ModelDownloadCancelled();
      if (pausedNow) throw const ModelDownloadPaused();
      rethrow;
    } finally {
      _cancelRequested.remove(model.tier);
      _pauseRequested.remove(model.tier);
      _clients.remove(model.tier);
      client.close(force: true);
    }
  }

  /// Removes the installed file *and* any partial — the picker's delete
  /// action also discards a paused download the user changed their mind on.
  void delete(M model) {
    for (final file in [fileOf(model), _partFileOf(model), _pausedFileOf(model)]) {
      if (file.existsSync()) file.deleteSync();
    }
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
