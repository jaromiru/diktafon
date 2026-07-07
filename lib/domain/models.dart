/// Domain entities (§4.1) — pure Dart, no I/O, no Flutter imports.
library;

/// Memo lifecycle (§4.3). A memo is always playable from `stored` onward;
/// everything after is best-effort enrichment.
enum MemoStatus {
  stored,
  transcribing,
  transcribed,
  summarizing,
  ready,
  failed;

  static MemoStatus fromName(String name) =>
      MemoStatus.values.firstWhere((s) => s.name == name);
}

/// A named, topic-based collection of memos, rendered as one continuous tape.
class Cassette {
  const Cassette({
    required this.id,
    required this.label,
    required this.titleIsUserSet,
    required this.colorSeed,
    required this.summary,
    required this.summaryUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Null → placeholder shown; auto-suggested once content exists (D10).
  final String? label;

  /// Once the user edits the label, auto-suggestions stop overwriting it (D10).
  final bool titleIsUserSet;

  /// Stable base for the segment palette ordering (§10.2).
  final int colorSeed;

  /// Rolling cassette summary (§6.7); null until first summarization.
  final String? summary;
  final DateTime? summaryUpdatedAt;
  final DateTime createdAt;

  /// Drives home-grid recency ordering (§5.2).
  final DateTime updatedAt;
}

/// One recording: immutable audio + derived artifacts.
class Memo {
  const Memo({
    required this.id,
    required this.cassetteId,
    required this.filePath,
    required this.durationMs,
    required this.createdAt,
    required this.status,
    this.detectedLang,
    this.transcript,
    this.memoSummary,
  });

  final String id;
  final String cassetteId;
  final String filePath;
  final int durationMs;

  /// Chronological tape order (D6): tape = memos ORDER BY createdAt.
  final DateTime createdAt;
  final MemoStatus status;
  final String? detectedLang;
  final Transcript? transcript;

  /// The 1–2 sentence "what the user meant to say" gist (§4.1).
  final String? memoSummary;
}

/// Structured transcription output (§6.3) — engine-agnostic.
class Transcript {
  const Transcript({required this.languageCode, required this.segments});

  final String languageCode;
  final List<Segment> segments;

  factory Transcript.fromJson(Map<String, dynamic> json) => Transcript(
        languageCode: json['lang'] as String,
        segments: (json['segments'] as List)
            .map((s) => Segment.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'lang': languageCode,
        'segments': segments.map((s) => s.toJson()).toList(),
      };

  bool get isEmpty => segments.every((s) => s.words.isEmpty);
}

class Segment {
  const Segment({
    required this.startMs,
    required this.endMs,
    required this.words,
  });

  final int startMs;
  final int endMs;
  final List<Word> words;

  factory Segment.fromJson(Map<String, dynamic> json) => Segment(
        startMs: json['s'] as int,
        endMs: json['e'] as int,
        words: (json['w'] as List)
            .map((w) => Word.fromJson(w as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        's': startMs,
        'e': endMs,
        'w': words.map((w) => w.toJson()).toList(),
      };
}

/// One timed word; offsets are local to the memo (§4.2 maps them globally).
class Word {
  const Word({required this.text, required this.startMs, required this.endMs});

  final String text;
  final int startMs;
  final int endMs;

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        text: json['t'] as String,
        startMs: json['s'] as int,
        endMs: json['e'] as int,
      );

  Map<String, dynamic> toJson() => {'t': text, 's': startMs, 'e': endMs};
}
