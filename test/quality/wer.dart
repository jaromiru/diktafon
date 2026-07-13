/// Word/character error rate scoring for the transcription quality bench
/// (docs/features/noise-robust-transcription.md, phase 0). Pure Dart.
///
/// Normalization before scoring: lowercase, every non-letter/non-digit run
/// becomes a single space. Diacritics are kept (they are meaning-bearing in
/// Czech). Standalone digits 0–20 are spelled out per language (references
/// write "deset", whisper emits "10"). A literal `[???]` in a reference
/// marks a word the human verifier could not discern — it matches any one
/// hypothesis word (or none) at zero cost and is excluded from the
/// reference length.
library;

/// Internal sentinel for `[???]` — letters-only so it survives
/// normalization; never occurs in real speech.
const wildcardToken = 'qqwildcardqq';

/// Counts from one minimum-edit alignment of hypothesis against reference.
class EditCounts {
  const EditCounts(this.substitutions, this.deletions, this.insertions,
      this.referenceLength);

  final int substitutions;
  final int deletions;
  final int insertions;
  final int referenceLength;

  int get errors => substitutions + deletions + insertions;

  /// (S+D+I)/N. An empty reference with a non-empty hypothesis rates 1.0.
  double get rate => referenceLength == 0
      ? (errors == 0 ? 0.0 : 1.0)
      : errors / referenceLength;
}

final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

const _digitWords = {
  'en': [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
    'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
    'sixteen', 'seventeen', 'eighteen', 'nineteen', 'twenty',
  ],
  'cs': [
    'nula', 'jedna', 'dva', 'tři', 'čtyři', 'pět', 'šest', 'sedm', 'osm',
    'devět', 'deset', 'jedenáct', 'dvanáct', 'třináct', 'čtrnáct', 'patnáct',
    'šestnáct', 'sedmnáct', 'osmnáct', 'devatenáct', 'dvacet',
  ],
};

/// Lowercased words with punctuation stripped — the scoring alphabet.
List<String> normalizeWords(String text, {String? language}) {
  final marked = text.replaceAll('[???]', ' $wildcardToken ');
  final digits = _digitWords[language];
  return marked
      .toLowerCase()
      .replaceAll(_nonWord, ' ')
      .trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) {
    if (digits == null) return w;
    final n = int.tryParse(w);
    return n != null && n >= 0 && n < digits.length ? digits[n] : w;
  }).toList();
}

EditCounts wordErrors(String reference, String hypothesis,
        {String? language}) =>
    _editCounts(normalizeWords(reference, language: language),
        normalizeWords(hypothesis, language: language));

/// CER over the same normalized text. `[???]` has no character-level
/// expansion — it is dropped from the reference (the hypothesis word it
/// covers counts as insertions; one clip, secondary metric).
EditCounts charErrors(String reference, String hypothesis,
    {String? language}) {
  final ref = normalizeWords(reference, language: language)
      .where((w) => w != wildcardToken);
  final hyp = normalizeWords(hypothesis, language: language);
  return _editCounts(ref.join(' ').split(''), hyp.join(' ').split(''));
}

/// Levenshtein alignment with S/D/I attribution (deletions = reference
/// items the hypothesis missed; insertions = extra hypothesis items).
/// [wildcardToken] in the reference matches or skips for free.
EditCounts _editCounts(List<String> ref, List<String> hyp) {
  final n = ref.length, m = hyp.length;
  bool wild(int i) => ref[i] == wildcardToken;
  int skipCost(int i) => wild(i) ? 0 : 1;

  // cost[i][j] = min edits aligning ref[i..] with hyp[j..].
  final cost = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    cost[i][m] = cost[i + 1][m] + skipCost(i);
  }
  for (var j = m - 1; j >= 0; j--) {
    cost[n][j] = m - j; // insert the rest of the hypothesis
  }
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      final match = ref[i] == hyp[j] || wild(i);
      final diagonal = cost[i + 1][j + 1] + (match ? 0 : 1);
      final deletion = cost[i + 1][j] + skipCost(i);
      final insertion = cost[i][j + 1] + 1;
      cost[i][j] = [diagonal, deletion, insertion]
          .reduce((a, b) => a < b ? a : b);
    }
  }

  var substitutions = 0, deletions = 0, insertions = 0;
  var i = 0, j = 0;
  while (i < n || j < m) {
    final canDiagonal = i < n && j < m;
    final match = canDiagonal && (ref[i] == hyp[j] || wild(i));
    if (match && cost[i][j] == cost[i + 1][j + 1]) {
      i++;
      j++;
    } else if (canDiagonal && cost[i][j] == cost[i + 1][j + 1] + 1) {
      substitutions++;
      i++;
      j++;
    } else if (i < n && cost[i][j] == cost[i + 1][j] + skipCost(i)) {
      if (!wild(i)) deletions++;
      i++;
    } else {
      insertions++;
      j++;
    }
  }
  final wildcards = [for (var k = 0; k < n; k++) wild(k)].where((w) => w);
  return EditCounts(substitutions, deletions, insertions,
      n - wildcards.length);
}
