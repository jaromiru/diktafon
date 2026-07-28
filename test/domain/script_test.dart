/// Script-aware join rules (§13 wave 2): CJK words sit flush, spaced
/// scripts keep their spaces, and the two conventions meet cleanly at
/// code-switching boundaries.
library;

import 'package:diktafon/domain/models.dart';
import 'package:diktafon/domain/script.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('joinWords', () {
    test('Latin words keep their spaces', () {
      expect(joinWords(['buy', 'milk', 'and', 'bread']),
          'buy milk and bread');
    });

    test('Korean is spaced like Latin — Hangul is not in the no-space class',
        () {
      expect(joinWords(['안녕하세요', '저는', '클로드입니다']),
          '안녕하세요 저는 클로드입니다');
    });

    test('Han words join flush', () {
      expect(joinWords(['今天', '天气', '很好']), '今天天气很好');
    });

    test('kana joins flush, including the prolonged-sound mark', () {
      expect(joinWords(['コー', 'ヒー', 'を', '飲む']), 'コーヒーを飲む');
    });

    test('CJK punctuation attaches without spaces on either side', () {
      expect(joinWords(['天气', '很好', '。', '走吧']), '天气很好。走吧');
      expect(joinWords(['「', 'こんにちは', '」']), '「こんにちは」');
    });

    test('code-switching keeps a space at the Latin↔CJK boundary', () {
      expect(joinWords(['我用', 'Flutter', '写的']), '我用 Flutter 写的');
    });

    test('astral Han (ext B) counts as CJK', () {
      expect(joinWords(['𠮷野', '家']), '𠮷野家');
    });

    test('iteration marks are word-forming, not punctuation', () {
      expect(joinWords(['人々', 'の']), '人々の');
    });

    test('empty inputs are harmless', () {
      expect(joinWords(<String>[]), '');
      expect(joinWords(['一']), '一');
    });
  });

  group('Transcript.plainText', () {
    test('joins CJK segments without spaces, Latin with', () {
      Transcript t(List<String> words) => Transcript(
            languageCode: 'x',
            segments: [
              Segment(startMs: 0, endMs: 1000, words: [
                for (final (i, w) in words.indexed)
                  Word(text: w, startMs: i * 10, endMs: i * 10 + 9),
              ]),
            ],
          );
      expect(t(['你好', '世界']).plainText, '你好世界');
      expect(t(['hello', 'world']).plainText, 'hello world');
    });
  });

  group('baseLanguageCode', () {
    test('strips script subtags, passes bare codes through', () {
      expect(baseLanguageCode('zh-Hans'), 'zh');
      expect(baseLanguageCode('zh-Hant'), 'zh');
      expect(baseLanguageCode('cs'), 'cs');
      expect(baseLanguageCode('yue'), 'yue');
    });
  });
}
