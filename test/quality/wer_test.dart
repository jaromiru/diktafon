import 'package:flutter_test/flutter_test.dart';

import 'wer.dart';

void main() {
  test('identical texts score zero', () {
    final counts = wordErrors('Hello world.', 'hello, WORLD');
    expect(counts.errors, 0);
    expect(counts.rate, 0);
    expect(counts.referenceLength, 2);
  });

  test('substitutions, deletions and insertions are attributed', () {
    expect(wordErrors('a b c', 'a x c').substitutions, 1);
    // b dropped, e appended — the unique minimal alignment.
    final counts = wordErrors('a b c d', 'a c d e');
    expect(counts.substitutions, 0);
    expect(counts.deletions, 1);
    expect(counts.insertions, 1);
    expect(counts.rate, closeTo(2 / 4, 1e-9));
  });

  test('ambiguous alignments still count total errors minimally', () {
    // 1S+1D+1I and 3S are both minimal; only the total is contractual.
    expect(wordErrors('a b c d', 'a x d e').errors, 3);
  });

  test('empty hypothesis is all deletions', () {
    final counts = wordErrors('one two three', '');
    expect(counts.deletions, 3);
    expect(counts.rate, 1.0);
  });

  test('diacritics are meaning-bearing, punctuation is not', () {
    expect(wordErrors('Byl jsem tam.', 'byl jsem tam').errors, 0);
    expect(wordErrors('být', 'byt').errors, 1,
        reason: 'diacritics distinguish Czech words');
  });

  test('normalizeWords collapses punctuation runs and dashes', () {
    expect(normalizeWords('dalo by se to - to hrubé audio…'),
        ['dalo', 'by', 'se', 'to', 'to', 'hrubé', 'audio']);
  });

  test('CER scores character edits within normalized text', () {
    final counts = charErrors('abcd', 'abed');
    expect(counts.substitutions, 1);
    expect(counts.referenceLength, 4);
  });

  test('[???] matches any one word or none, free of charge', () {
    final matched = wordErrors('šel jsem [???] domů', 'šel jsem rychle domů');
    expect(matched.errors, 0);
    expect(matched.referenceLength, 3, reason: 'wildcard is not counted');

    final skipped = wordErrors('šel jsem [???] domů', 'šel jsem domů');
    expect(skipped.errors, 0);

    final twoExtra = wordErrors('šel jsem [???] domů', 'šel jsem moc rychle domů');
    expect(twoExtra.errors, 1, reason: 'wildcard covers only one word');
  });

  test('standalone digits are spelled out per language', () {
    expect(wordErrors('rozměr osm a deset', 'rozměr 8 a 10', language: 'cs')
        .errors, 0);
    expect(wordErrors('number ten', 'number 10', language: 'en').errors, 0);
    expect(wordErrors('rok 2026', 'rok 2026', language: 'cs').errors, 0,
        reason: 'large numbers stay digits');
  });
}
