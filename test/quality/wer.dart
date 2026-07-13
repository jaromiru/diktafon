/// Word/character error rate scoring for the transcription quality bench
/// (docs/features/noise-robust-transcription.md, phase 0). Pure Dart.
///
/// Normalization before scoring: lowercase, every non-letter/non-digit run
/// becomes a single space. Diacritics are kept (they are meaning-bearing in
/// Czech); numerals are not spelled out (the fixtures contain none).
library;

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

/// Lowercased words with punctuation stripped — the scoring alphabet.
List<String> normalizeWords(String text) => text
    .toLowerCase()
    .replaceAll(_nonWord, ' ')
    .trim()
    .split(' ')
    .where((w) => w.isNotEmpty)
    .toList();

EditCounts wordErrors(String reference, String hypothesis) =>
    _editCounts(normalizeWords(reference), normalizeWords(hypothesis));

EditCounts charErrors(String reference, String hypothesis) => _editCounts(
      normalizeWords(reference).join(' ').split(''),
      normalizeWords(hypothesis).join(' ').split(''),
    );

/// Levenshtein alignment with S/D/I attribution (deletions = reference
/// items the hypothesis missed; insertions = extra hypothesis items).
EditCounts _editCounts(List<String> ref, List<String> hyp) {
  final n = ref.length, m = hyp.length;
  // cost[i][j] = min edits aligning ref[i..] with hyp[j..].
  final cost = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    cost[i][m] = n - i; // delete the rest of the reference
  }
  for (var j = m - 1; j >= 0; j--) {
    cost[n][j] = m - j; // insert the rest of the hypothesis
  }
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      if (ref[i] == hyp[j]) {
        cost[i][j] = cost[i + 1][j + 1];
      } else {
        cost[i][j] = 1 +
            [cost[i + 1][j + 1], cost[i + 1][j], cost[i][j + 1]]
                .reduce((a, b) => a < b ? a : b);
      }
    }
  }

  var substitutions = 0, deletions = 0, insertions = 0;
  var i = 0, j = 0;
  while (i < n || j < m) {
    if (i < n && j < m && ref[i] == hyp[j]) {
      i++;
      j++;
    } else if (i < n && j < m && cost[i][j] == cost[i + 1][j + 1] + 1) {
      substitutions++;
      i++;
      j++;
    } else if (i < n && cost[i][j] == cost[i + 1][j] + 1) {
      deletions++;
      i++;
    } else {
      insertions++;
      j++;
    }
  }
  return EditCounts(substitutions, deletions, insertions, n);
}
