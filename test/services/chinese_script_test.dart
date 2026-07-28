/// D8 amendment (§13 wave 2): whisper's one `zh` → the user's script,
/// converted char-level so word boundaries and timings survive exactly.
library;

import 'package:diktafon/domain/models.dart';
import 'package:diktafon/domain/script.dart';
import 'package:diktafon/services/processing/chinese_script.dart';
import 'package:flutter_test/flutter_test.dart';

Transcript zhTranscript(List<String> words, {String lang = 'zh'}) =>
    Transcript(languageCode: lang, segments: [
      Segment(startMs: 0, endMs: words.length * 100, words: [
        for (final (i, w) in words.indexed)
          Word(text: w, startMs: i * 100, endMs: i * 100 + 90),
      ]),
    ]);

void main() {
  group('char-level conversion', () {
    test('simplified → traditional, most frequent variant', () {
      expect(toTraditional('万事开头难'), '萬事開頭難');
      expect(toTraditional('语音备忘'), '語音備忘');
    });

    test('traditional → simplified', () {
      expect(toSimplified('萬事開頭難'), '万事开头难');
      expect(toSimplified('髮'), '发');
      expect(toSimplified('發'), '发');
    });

    test('shared chars, Latin, digits and punctuation pass through', () {
      expect(toTraditional('今天 3 点，OK。'), '今天 3 點，OK。');
      expect(toSimplified('hello world'), 'hello world');
    });

    test('conversion is codepoint-aligned — length in runes is preserved',
        () {
      const sample = '这是一个很长的测试句子，包括标点符号。';
      expect(toTraditional(sample).runes.length, sample.runes.length);
    });
  });

  group('zhScriptFor', () {
    test('explicit script wins; else region; else Hans', () {
      expect(zhScriptFor(scriptCode: 'Hant', countryCode: 'CN'), 'Hant');
      expect(zhScriptFor(scriptCode: 'Hans', countryCode: 'TW'), 'Hans');
      expect(zhScriptFor(countryCode: 'TW'), 'Hant');
      expect(zhScriptFor(countryCode: 'HK'), 'Hant');
      expect(zhScriptFor(countryCode: 'MO'), 'Hant');
      expect(zhScriptFor(countryCode: 'CN'), 'Hans');
      expect(zhScriptFor(countryCode: 'SG'), 'Hans');
      expect(zhScriptFor(), 'Hans');
    });
  });

  group('resolveChineseScript', () {
    test('forced zh-Hant converts and tags, whatever whisper emitted', () {
      final resolved = resolveChineseScript(
        zhTranscript(['语音', '备忘']),
        appLanguage: 'zh-Hant',
        systemZhScript: () => fail('forced script never asks the system'),
      );
      expect(resolved.languageCode, 'zh-Hant');
      expect(resolved.plainText, '語音備忘');
    });

    test('forced zh-Hans normalizes whisper\'s mixed output to Simplified',
        () {
      final resolved = resolveChineseScript(
        zhTranscript(['語音', '备忘']),
        appLanguage: 'zh-Hans',
        systemZhScript: () => 'Hant',
      );
      expect(resolved.languageCode, 'zh-Hans');
      expect(resolved.plainText, '语音备忘');
    });

    test('auto-detected zh takes the script from the system locale', () {
      final resolved = resolveChineseScript(
        zhTranscript(['语音', '备忘']),
        appLanguage: null,
        systemZhScript: () => 'Hant',
      );
      expect(resolved.languageCode, 'zh-Hant');
      expect(resolved.plainText, '語音備忘');
    });

    test('word boundaries and timings survive conversion exactly', () {
      final resolved = resolveChineseScript(
        zhTranscript(['万事', '开头', '难']),
        appLanguage: null,
        systemZhScript: () => 'Hant',
      );
      final words = resolved.segments.single.words;
      expect(words.map((w) => w.text), ['萬事', '開頭', '難']);
      expect(words.map((w) => w.startMs), [0, 100, 200]);
      expect(words.map((w) => w.endMs), [90, 190, 290]);
    });

    test('non-Chinese and yue transcripts pass through untouched', () {
      final cs = zhTranscript(['dobrý', 'den'], lang: 'cs');
      expect(resolveChineseScript(cs,
              appLanguage: null, systemZhScript: () => 'Hant'),
          same(cs));
      final yue = zhTranscript(['廣東話'], lang: 'yue');
      expect(resolveChineseScript(yue,
              appLanguage: null, systemZhScript: () => 'Hans'),
          same(yue));
    });

    test('a non-zh language override never converts', () {
      final t = zhTranscript(['语音']);
      expect(resolveChineseScript(t,
              appLanguage: 'ko', systemZhScript: () => 'Hant'),
          same(t));
    });
  });

  group('matchChineseScript (LLM belt-and-braces)', () {
    test('pins gists/titles to the target script; other languages pass', () {
      expect(matchChineseScript('语音备忘', 'zh-Hant'), '語音備忘');
      expect(matchChineseScript('語音備忘', 'zh-Hans'), '语音备忘');
      expect(matchChineseScript('shopping list', 'en'), 'shopping list');
    });
  });
}
