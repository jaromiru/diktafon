/// The summarization model catalog (§6.6): small multilingual instruct LLMs
/// in GGUF, pinned from the git-lfs pointers at huggingface.co/Qwen
/// (2026-07-08). Download/verify mechanics live in the shared ModelManager.
///
/// Qwen3 was picked over the design-doc candidates (Qwen2.5-3B is
/// research-licensed, Llama-3.2 has no official Czech/Polish support):
/// Apache-2.0, strong small-size multilingual quality incl. Czech & Polish
/// (§16 quality validation happens behind this seam).
library;

import '../model_manager.dart';

/// One downloadable summarization model.
class LlmModel implements ModelSpec {
  const LlmModel({
    required this.tier,
    required this.label,
    required this.description,
    required this.repo,
    required this.fileName,
    required this.sizeBytes,
    required this.sha256Hex,
    required this.contextTokens,
    this.minRamGb = 0,
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

  /// HF repo the file lives in, e.g. 'Qwen/Qwen3-1.7B-GGUF'.
  final String repo;

  /// Context window the provider requests (bounds KV-cache RAM and how much
  /// transcript fits into one summarization call).
  final int contextTokens;

  /// Soft device gate for the Settings picker; 0 = ungated.
  final int minRamGb;

  /// Tests point this at a local server; production uses the HF mirror.
  final Uri? urlOverride;

  @override
  Uri get url =>
      urlOverride ??
      Uri.parse('https://huggingface.co/$repo/resolve/main/$fileName');

  @override
  String get sizeLabel =>
      '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';

  static const qwen3_0_6b = LlmModel(
    tier: 'qwen3-0.6b',
    label: 'Qwen3 0.6B',
    description: 'For quick tests only — not offered to users.',
    repo: 'Qwen/Qwen3-0.6B-GGUF',
    fileName: 'Qwen3-0.6B-Q8_0.gguf',
    sizeBytes: 639446688,
    sha256Hex:
        '9465e63a22add5354d9bb4b99e90117043c7124007664907259bd16d043bb031',
    contextTokens: 4096,
    listed: false,
  );

  static const qwen3_1_7b = LlmModel(
    tier: 'qwen3-1.7b',
    label: 'Qwen3 1.7B',
    description: 'Recommended — compact multilingual summaries.',
    repo: 'Qwen/Qwen3-1.7B-GGUF',
    fileName: 'Qwen3-1.7B-Q8_0.gguf',
    sizeBytes: 1834426016,
    sha256Hex:
        '061b54daade076b5d3362dac252678d17da8c68f07560be70818cace6590cb1a',
    contextTokens: 4096,
  );

  static const qwen3_4b = LlmModel(
    tier: 'qwen3-4b',
    label: 'Qwen3 4B',
    description: 'Higher-quality summaries & titles; needs a capable device '
        '(~3 GB RAM while summarizing).',
    repo: 'Qwen/Qwen3-4B-GGUF',
    fileName: 'Qwen3-4B-Q4_K_M.gguf',
    sizeBytes: 2497280256,
    sha256Hex:
        '7485fe6f11af29433bc51cab58009521f205840f5b4ae3a32fa7f92e8534fdf5',
    contextTokens: 4096,
    minRamGb: 6,
  );

  static const all = [qwen3_0_6b, qwen3_1_7b, qwen3_4b];

  static LlmModel byTier(String tier) =>
      all.firstWhere((m) => m.tier == tier, orElse: () => qwen3_1_7b);
}

typedef LlmModelState = ModelState<LlmModel>;

class LlmModelManager extends ModelManager<LlmModel> {
  LlmModelManager(
    super.dir, {
    super.httpClientFactory,
    super.catalog = LlmModel.all,
  });
}
