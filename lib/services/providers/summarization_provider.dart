/// The summarization seam (§6.3, D3) — local small LLM by default, swappable
/// without touching UI or domain layers.
library;

import 'dart:async';

import '../../domain/models.dart';
import 'transcription_provider.dart' show ModelStatus, ProgressSink;

/// What the cassette-summary job needs to know about a newly added memo.
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

  /// Fixes obvious recognition errors in a fresh transcript (§6.8):
  /// misheard words, spelling, punctuation — never the language, meaning or
  /// segment structure. Best-effort by contract: where the engine is
  /// unsure, the input's text comes back verbatim. Word timings inside a
  /// changed segment are re-estimated.
  Future<Transcript> cleanTranscript(Transcript t,
      {required String languageCode});

  /// The 1–2 sentence "what the user meant to say" gist (§6.7).
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
