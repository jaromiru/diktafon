/// The summarization seam (§6.3, D3) — local small LLM by default, swappable
/// without touching UI or domain layers.
library;

import 'dart:async';

import '../../domain/models.dart';
import 'transcription_provider.dart' show ModelStatus, ProgressSink;

/// One memo's contribution to the cassette summary: its gist, or — for
/// short memos that never get one (§6.7) — the transcript text itself.
class MemoDigest {
  const MemoDigest({required this.memoSummary, required this.createdAt});
  final String memoSummary;
  final DateTime createdAt;
}

abstract interface class SummarizationProvider {
  /// e.g. "llama.cpp/qwen2.5-3b-q4"
  String get id;

  Future<ModelStatus> modelStatus();
  Future<void> ensureModel({ProgressSink? onProgress});

  /// The one-sentence "what the user meant to say" gist (§6.7) — only
  /// called for transcripts past the length gate.
  Future<String> summarizeMemo(Transcript t, {required String languageCode});

  /// Incrementally folds new memos into the running summary (§6.7).
  Future<String> updateCassetteSummary({
    required String? previousSummary,
    required List<MemoDigest> newMemos,
    required String languageCode,
  });

  Future<String> suggestTitle(
    String cassetteSummary, {
    required String languageCode,
  });
}
