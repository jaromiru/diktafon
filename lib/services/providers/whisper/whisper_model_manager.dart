/// Model provisioning (§6.6): whisper models are downloaded on demand into
/// `<app-support>/models/whisper/` (regenerable — excluded from backup, §7.1)
/// with streamed progress and sha256 verification against pinned upstream
/// hashes (a truncated/corrupt model would crash native code).
library;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../transcription_provider.dart';

/// One downloadable model tier. Hashes/sizes pinned from the git-lfs pointers
/// at huggingface.co/ggerganov/whisper.cpp (2026-07-07).
class WhisperModel {
  const WhisperModel({
    required this.tier,
    required this.label,
    required this.description,
    required this.fileName,
    required this.sizeBytes,
    required this.sha256Hex,
    this.listed = true,
    this.urlOverride,
  });

  final String tier;
  final String label;
  final String description;
  final String fileName;
  final int sizeBytes;
  final String sha256Hex;

  /// Unlisted tiers don't appear in the Settings picker unless installed
  /// (tiny exists for tests/dev — too weak for Czech/Polish, §6.6).
  final bool listed;

  /// Tests point this at a local server; production uses the HF mirror.
  final Uri? urlOverride;

  Uri get url =>
      urlOverride ??
      Uri.parse(
          'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$fileName');

  String get sizeLabel => '${(sizeBytes / (1024 * 1024)).round()} MB';

  static const tiny = WhisperModel(
    tier: 'tiny',
    label: 'Whisper tiny',
    description: 'For quick tests only — not offered to users.',
    fileName: 'ggml-tiny-q5_1.bin',
    sizeBytes: 32152673,
    sha256Hex:
        '818710568da3ca15689e31a743197b520007872ff9576237bda97bd1b469c3d7',
    listed: false,
  );

  static const small = WhisperModel(
    tier: 'small',
    label: 'Whisper small',
    description: 'Recommended — best size/quality balance for all seven '
        'languages, incl. Czech & Polish.',
    fileName: 'ggml-small-q5_1.bin',
    sizeBytes: 190085487,
    sha256Hex:
        'ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb',
  );

  static const largeV3Turbo = WhisperModel(
    tier: 'large-v3-turbo',
    label: 'Whisper large-v3-turbo',
    description: 'Higher accuracy; needs a capable device (~2.5 GB RAM '
        'while transcribing).',
    fileName: 'ggml-large-v3-turbo-q5_0.bin',
    sizeBytes: 574041195,
    sha256Hex:
        '394221709cd5ad1f40c46e6031ca61bce88931e6e088c188294c6d5a55ffa7e2',
  );

  static const all = [tiny, small, largeV3Turbo];

  static WhisperModel byTier(String tier) =>
      all.firstWhere((m) => m.tier == tier, orElse: () => small);
}

/// Snapshot of one tier for the Settings picker.
class WhisperModelState {
  const WhisperModelState(this.model, this.status, this.progress);

  final WhisperModel model;
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

class WhisperModelManager {
  WhisperModelManager(
    this._dir, {
    HttpClient Function()? httpClientFactory,
    this.catalog = WhisperModel.all,
  }) : _httpClientFactory = httpClientFactory ?? HttpClient.new;

  final Directory _dir;
  final HttpClient Function() _httpClientFactory;

  /// The tiers this install knows about; tests swap in local specs.
  final List<WhisperModel> catalog;

  final _changes = StreamController<void>.broadcast();
  final Map<String, double> _progress = {};
  final Map<String, Future<void>> _downloads = {};

  /// Emits whenever any tier's status/progress changes.
  Stream<void> get changes => _changes.stream;

  File fileOf(WhisperModel model) =>
      File('${_dir.path}/${model.fileName}');

  ModelStatus statusOf(WhisperModel model) {
    if (_downloads.containsKey(model.tier)) return ModelStatus.downloading;
    return fileOf(model).existsSync()
        ? ModelStatus.ready
        : ModelStatus.notInstalled;
  }

  WhisperModelState stateOf(WhisperModel model) => WhisperModelState(
      model, statusOf(model), _progress[model.tier] ?? 0);

  List<WhisperModelState> snapshot() =>
      [for (final model in catalog) stateOf(model)];

  /// Total disk footprint of installed models (Settings shows storage used).
  int installedBytes() => catalog
      .map((m) => fileOf(m))
      .where((f) => f.existsSync())
      .fold(0, (sum, f) => sum + f.lengthSync());

  /// Downloads and verifies a tier; concurrent calls for the same tier join
  /// the in-flight download. Progress is reported both through [onProgress]
  /// and the [changes] stream.
  Future<void> download(WhisperModel model, {ProgressSink? onProgress}) {
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

  Future<void> _download(WhisperModel model, ProgressSink? onProgress) async {
    await _dir.create(recursive: true);
    final part = File('${fileOf(model).path}.part');
    final client = _httpClientFactory();
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
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  void delete(WhisperModel model) {
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
