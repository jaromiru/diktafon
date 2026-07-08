/// The whisper model catalog (§6.6): tiers pinned from the git-lfs pointers
/// at huggingface.co/ggerganov/whisper.cpp (2026-07-07). Download/verify
/// mechanics live in the shared ModelManager.
library;

import '../model_manager.dart';

export '../model_manager.dart' show ModelVerificationException;

/// One downloadable whisper tier.
class WhisperModel implements ModelSpec {
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

  @override
  final String tier;
  @override
  final String label;
  @override
  final String description;
  @override
  final String fileName;
  @override
  final int sizeBytes;
  @override
  final String sha256Hex;
  @override
  final bool listed;

  /// Tests point this at a local server; production uses the HF mirror.
  final Uri? urlOverride;

  @override
  Uri get url =>
      urlOverride ??
      Uri.parse(
          'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$fileName');

  @override
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

typedef WhisperModelState = ModelState<WhisperModel>;

class WhisperModelManager extends ModelManager<WhisperModel> {
  WhisperModelManager(
    super.dir, {
    super.httpClientFactory,
    super.catalog = WhisperModel.all,
  });
}
