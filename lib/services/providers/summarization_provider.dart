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

/// M3 placeholder — see NotInstalledTranscriptionProvider for semantics.
class NotInstalledSummarizationProvider implements SummarizationProvider {
  const NotInstalledSummarizationProvider();

  @override
  String get id => 'none/summarization';

  @override
  Future<ModelStatus> modelStatus() async => ModelStatus.notInstalled;

  @override
  Future<void> ensureModel({ProgressSink? onProgress}) async {
    throw UnsupportedError('no summarization engine shipped yet (M3)');
  }

  @override
  Future<String> summarizeMemo(Transcript t, {required String languageCode}) {
    throw StateError('summarization model not installed');
  }

  @override
  Future<String> updateCassetteSummary({
    required String? previousSummary,
    required List<MemoDigest> newMemos,
    required String languageCode,
  }) {
    throw StateError('summarization model not installed');
  }

  @override
  Future<String> suggestTitle(
    String cassetteSummary, {
    required String languageCode,
  }) {
    throw StateError('summarization model not installed');
  }
}
