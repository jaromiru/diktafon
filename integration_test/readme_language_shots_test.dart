/// README language-row screenshots: boots the real app once per supported
/// locale over the "Kitchen renovation" demo cassette with its label, summary,
/// transcripts, and gists translated into that language, opens the cassette,
/// parks the playhead mid-tape, and captures a phone-ratio shot. No ML engine
/// runs — enrichment is pre-seeded, exactly like store_screenshots_test.dart.
///
///   DIKTAFON_TEST_DIR=/tmp/dk_lang \
///   flutter test integration_test/readme_language_shots_test.dart -d linux
///
/// Shots land in $DIKTAFON_TEST_DIR/shots/<code>.png; the README language row
/// uses them cropped to the memo-counter → timeline → memo-1-gist strip
/// (ffmpeg crop, see media/lang/) — memo 1 gists are kept ≤ 2 lines in every
/// language so one crop height fits all.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:diktafon/app.dart';
import 'package:diktafon/application/providers.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/files/audio_file_store.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/providers/llm/llm_model_manager.dart';
import 'package:diktafon/services/providers/whisper/whisper_model_manager.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

final _boundaryKey = GlobalKey();
late Directory _workDir;
late File _toneFile;

Future<void> _settle(WidgetTester tester, {int frames = 20}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  await _settle(tester, frames: 5);
  final dir = Directory('${_workDir.path}/shots')..createSync(recursive: true);
  final boundary =
      _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// ~185 words/min cadence over one segment per sentence.
Transcript _transcript(String lang, List<String> sentences) {
  var cursor = 0;
  final segments = <Segment>[];
  for (final sentence in sentences) {
    final words = sentence.split(' ');
    segments.add(Segment(
      startMs: cursor,
      endMs: cursor + words.length * 325,
      words: [
        for (final (i, w) in words.indexed)
          Word(
              text: w,
              startMs: cursor + i * 325,
              endMs: cursor + i * 325 + 300),
      ],
    ));
    cursor += words.length * 325 + 500;
  }
  return Transcript(languageCode: lang, segments: segments);
}

class _Memo {
  const _Memo(this.sentences, this.gist);
  final List<String> sentences;
  final String gist;
}

class _Loc {
  const _Loc(this.code, this.label, this.summary, this.memos);
  final String code;
  final String label;
  final String summary;
  final List<_Memo> memos; // measure, quote, colors — oldest first
}

/// The store-screenshot "Kitchen renovation" cassette, translated. Content
/// mirrors store_screenshots_test.dart so the row reads as one screen.
const _locales = [
  _Loc(
    'en',
    'Kitchen renovation',
    'The kitchen refit is moving: measurements are done, the contractor '
        'quote lands on Thursday, and the cabinet color is down to sage '
        'green or off-white. Every appliance stays except the oven.',
    [
      _Memo([
        'Measured the whole kitchen this morning.',
        'The window wall is three meters twenty and the counter run is two '
            'forty, with seventy centimeters left for the fridge.',
        'One thing to remember, the radiator pipe sticks out on the left, '
            'so the corner cabinet needs a cutout.',
      ], 'Kitchen measured; the corner cabinet needs a radiator cutout.'),
      _Memo([
        'Called Hanson about the quote.',
        'He can start in the second week of next month and the full number '
            'arrives by Thursday.',
        'Demolition is included but disposal is extra, roughly two hundred.',
      ], 'Hanson can start in the second week of next month; the full quote '
          'arrives Thursday. Demolition included, disposal ~200 extra.'),
      _Memo([
        'Cabinet colors, round three.',
        'I keep coming back to sage green, but the off-white would make the '
            'room feel bigger.',
        'Maybe green below and white above.',
        'Also decided that every appliance stays except the oven, that one '
            'is done for.',
      ], 'Cabinet color is down to sage green vs. off-white, possibly '
          'split. All appliances stay except the oven.'),
    ],
  ),
  _Loc(
    'cs',
    'Rekonstrukce kuchyně',
    'Přestavba kuchyně se hýbe: měření je hotové, nabídka od řemeslníka '
        'dorazí ve čtvrtek a barva skříněk se rozhoduje mezi šalvějově '
        'zelenou a krémově bílou. Všechny spotřebiče zůstávají, kromě trouby.',
    [
      _Memo([
        'Dnes ráno jsem přeměřil celou kuchyni.',
        'Stěna s oknem má tři metry dvacet a linka dva čtyřicet, na lednici '
            'zbývá sedmdesát centimetrů.',
        'Jedna věc k zapamatování, vlevo vyčnívá trubka od radiátoru, takže '
            'rohová skříňka potřebuje výřez.',
      ], 'Kuchyň přeměřena; rohová skříňka potřebuje výřez na trubku.'),
      _Memo([
        'Volal jsem Hansonovi kvůli nabídce.',
        'Může začít druhý týden příštího měsíce a celková cena dorazí do '
            'čtvrtka.',
        'Bourání je v ceně, ale odvoz suti je zvlášť, zhruba dvě stě.',
      ], 'Hanson může začít druhý týden příštího měsíce; celá nabídka '
          'dorazí ve čtvrtek. Bourání v ceně, odvoz ~200 navíc.'),
      _Memo([
        'Barvy skříněk, třetí kolo.',
        'Pořád se vracím k šalvějově zelené, ale s krémově bílou by '
            'místnost působila větší.',
        'Možná zelená dole a bílá nahoře.',
        'Taky jsem rozhodl, že všechny spotřebiče zůstanou, kromě trouby, '
            'ta už dosloužila.',
      ], 'Barva skříněk: šalvějově zelená vs. krémově bílá, možná '
          'kombinace. Spotřebiče zůstávají, kromě trouby.'),
    ],
  ),
  _Loc(
    'de',
    'Küchenrenovierung',
    'Der Küchenumbau kommt voran: Das Ausmessen ist erledigt, das Angebot '
        'des Handwerkers kommt am Donnerstag, und bei der Schrankfarbe '
        'stehen Salbeigrün oder Cremeweiß zur Wahl. Alle Geräte bleiben, '
        'nur der Ofen nicht.',
    [
      _Memo([
        'Heute Morgen die ganze Küche ausgemessen.',
        'Die Fensterwand misst drei Meter zwanzig und die Arbeitszeile zwei '
            'vierzig, für den Kühlschrank bleiben siebzig Zentimeter.',
        'Nicht vergessen, links steht das Heizungsrohr vor, der Eckschrank '
            'braucht also einen Ausschnitt.',
      ], 'Küche vermessen; der Eckschrank braucht einen Rohr-Ausschnitt.'),
      _Memo([
        'Hanson wegen des Angebots angerufen.',
        'Er kann in der zweiten Woche des nächsten Monats anfangen, die '
            'endgültige Zahl kommt bis Donnerstag.',
        'Abriss ist inklusive, aber die Entsorgung kostet extra, ungefähr '
            'zweihundert.',
      ], 'Hanson kann in der zweiten Woche des nächsten Monats anfangen; '
          'das volle Angebot kommt Donnerstag. Abriss inklusive, Entsorgung '
          '~200 extra.'),
      _Memo([
        'Schrankfarben, Runde drei.',
        'Ich komme immer wieder auf Salbeigrün zurück, aber Cremeweiß würde '
            'den Raum größer wirken lassen.',
        'Vielleicht unten grün und oben weiß.',
        'Außerdem entschieden: Alle Geräte bleiben, nur der Ofen nicht, der '
            'ist durch.',
      ], 'Schrankfarbe: Salbeigrün oder Cremeweiß, vielleicht geteilt. Alle '
          'Geräte bleiben außer dem Ofen.'),
    ],
  ),
  _Loc(
    'es',
    'Reforma de la cocina',
    'La reforma de la cocina avanza: las medidas están tomadas, el '
        'presupuesto del contratista llega el jueves y el color de los '
        'armarios está entre verde salvia y blanco roto. Todos los '
        'electrodomésticos se quedan menos el horno.',
    [
      _Memo([
        'Esta mañana medí toda la cocina.',
        'La pared de la ventana mide tres metros veinte y la encimera dos '
            'cuarenta, con setenta centímetros libres para la nevera.',
        'Una cosa a recordar: el tubo del radiador sobresale a la '
            'izquierda, así que el armario de la esquina necesita un '
            'recorte.',
      ], 'Cocina medida; el armario de la esquina necesita un recorte.'),
      _Memo([
        'Llamé a Hanson por el presupuesto.',
        'Puede empezar la segunda semana del mes que viene y la cifra '
            'completa llega el jueves.',
        'La demolición está incluida pero la retirada de escombros se paga '
            'aparte, unos doscientos.',
      ], 'Hanson puede empezar la segunda semana del mes que viene; el '
          'presupuesto completo llega el jueves. Demolición incluida, '
          'escombros ~200 aparte.'),
      _Memo([
        'Colores de los armarios, tercera ronda.',
        'Sigo volviendo al verde salvia, pero el blanco roto haría la '
            'habitación más grande.',
        'Quizá verde abajo y blanco arriba.',
        'También decidido: todos los electrodomésticos se quedan menos el '
            'horno, ese ya no da más.',
      ], 'El color de los armarios está entre verde salvia y blanco roto, '
          'quizá combinados. Todo se queda menos el horno.'),
    ],
  ),
  _Loc(
    'fr',
    'Rénovation de la cuisine',
    'La rénovation de la cuisine avance : les mesures sont prises, le '
        'devis de l\'artisan arrive jeudi et la couleur des placards se '
        'joue entre vert sauge et blanc cassé. Tous les appareils restent, '
        'sauf le four.',
    [
      _Memo([
        'Ce matin, j\'ai mesuré toute la cuisine.',
        'Le mur de la fenêtre fait trois mètres vingt et le plan de travail '
            'deux quarante, avec soixante-dix centimètres pour le frigo.',
        'À retenir : le tuyau du radiateur dépasse à gauche, le placard '
            'd\'angle aura donc besoin d\'une découpe.',
      ], 'Cuisine mesurée ; le placard d\'angle doit être découpé.'),
      _Memo([
        'J\'ai appelé Hanson pour le devis.',
        'Il peut commencer la deuxième semaine du mois prochain et le '
            'chiffre complet arrive d\'ici jeudi.',
        'La démolition est comprise mais l\'évacuation est en plus, environ '
            'deux cents.',
      ], 'Hanson peut commencer la deuxième semaine du mois prochain ; le '
          'devis complet arrive jeudi. Démolition comprise, évacuation '
          '~200 en plus.'),
      _Memo([
        'Couleurs des placards, troisième manche.',
        'Je reviens toujours au vert sauge, mais le blanc cassé agrandirait '
            'la pièce.',
        'Peut-être vert en bas et blanc en haut.',
        'Décidé aussi : tous les appareils restent sauf le four, il est '
            'fichu.',
      ], 'Couleur des placards : vert sauge ou blanc cassé, peut-être les '
          'deux. Tout reste sauf le four.'),
    ],
  ),
  _Loc(
    'ko',
    '주방 리모델링',
    '주방 공사가 진행 중이다. 실측은 끝났고 시공업체 견적은 목요일에 나오며, '
        '수납장 색은 세이지 그린과 오프화이트로 좁혀졌다. 오븐만 빼고 가전은 '
        '모두 그대로 쓴다.',
    [
      _Memo([
        '오늘 아침에 주방 전체를 실측했다.',
        '창가 벽은 3미터 20, 조리대 쪽은 2미터 40이고 냉장고 자리는 70센티미터가 남는다.',
        '기억할 것 하나, 왼쪽에 라디에이터 배관이 튀어나와 있어서 코너 수납장에 홈을 파야 한다.',
      ], '주방 실측 완료. 코너 수납장은 배관 때문에 홈이 필요하다.'),
      _Memo([
        '견적 때문에 핸슨 씨에게 전화했다.',
        '다음 달 둘째 주에 시작할 수 있고, 최종 금액은 목요일까지 나온다고 한다.',
        '철거는 포함이지만 폐기물 처리는 별도로 200 정도 든다.',
      ], '핸슨 씨는 다음 달 둘째 주에 시작 가능. 최종 견적은 목요일. 철거 포함, '
          '폐기물 처리 ~200 별도.'),
      _Memo([
        '수납장 색 고르기, 세 번째.',
        '자꾸 세이지 그린으로 마음이 가는데, 오프화이트가 방을 더 넓어 보이게 할 것 같다.',
        '아래는 초록, 위는 흰색도 괜찮겠다.',
        '그리고 가전은 오븐만 빼고 다 그대로 쓰기로 했다. 오븐은 수명이 다했다.',
      ], '수납장 색은 세이지 그린 대 오프화이트, 상하 조합도 고려. 오븐만 '
          '교체하고 가전은 유지.'),
    ],
  ),
  _Loc(
    'pl',
    'Remont kuchni',
    'Remont kuchni idzie do przodu: pomiary zrobione, wycena od wykonawcy '
        'przyjdzie w czwartek, a kolor szafek rozstrzyga się między '
        'szałwiową zielenią a złamaną bielą. Wszystkie sprzęty zostają '
        'oprócz piekarnika.',
    [
      _Memo([
        'Dziś rano zmierzyłem całą kuchnię.',
        'Ściana z oknem ma trzy metry dwadzieścia, a blat dwa czterdzieści, '
            'na lodówkę zostaje siedemdziesiąt centymetrów.',
        'Jedna rzecz do zapamiętania: po lewej wystaje rura od kaloryfera, '
            'więc szafka narożna potrzebuje wycięcia.',
      ], 'Kuchnia zmierzona; szafka narożna wymaga wycięcia na rurę.'),
      _Memo([
        'Dzwoniłem do Hansona w sprawie wyceny.',
        'Może zacząć w drugim tygodniu przyszłego miesiąca, a pełna kwota '
            'będzie do czwartku.',
        'Wyburzanie jest w cenie, ale wywóz gruzu ekstra, jakieś dwieście.',
      ], 'Hanson może zacząć w drugim tygodniu przyszłego miesiąca; pełna '
          'wycena w czwartek. Wyburzanie w cenie, wywóz ~200 dodatkowo.'),
      _Memo([
        'Kolory szafek, runda trzecia.',
        'Ciągle wracam do szałwiowej zieleni, ale złamana biel '
            'powiększyłaby wnętrze.',
        'Może zielone na dole i białe na górze.',
        'Zdecydowane też, że wszystkie sprzęty zostają oprócz piekarnika, '
            'ten jest już do wymiany.',
      ], 'Kolor szafek: szałwiowa zieleń vs. złamana biel, może łączone. '
          'Sprzęty zostają oprócz piekarnika.'),
    ],
  ),
  _Loc(
    'pt',
    'Reforma da cozinha',
    'A reforma da cozinha avança: as medições estão feitas, o orçamento do '
        'empreiteiro chega na quinta-feira e a cor dos armários está entre '
        'verde-sálvia e branco-pérola. Todos os eletrodomésticos ficam, '
        'menos o forno.',
    [
      _Memo([
        'Medi a cozinha inteira esta manhã.',
        'A parede da janela tem três metros e vinte e a bancada dois e '
            'quarenta, sobrando setenta centímetros para a geladeira.',
        'Uma coisa para lembrar: o cano do radiador sobressai à esquerda, '
            'então o armário de canto precisa de um recorte.',
      ], 'Cozinha medida; o armário de canto precisa de um recorte.'),
      _Memo([
        'Liguei para o Hanson por causa do orçamento.',
        'Ele pode começar na segunda semana do próximo mês e o valor final '
            'chega até quinta.',
        'A demolição está incluída, mas a remoção do entulho é à parte, uns '
            'duzentos.',
      ], 'O Hanson pode começar na segunda semana do próximo mês; o '
          'orçamento completo chega na quinta. Demolição incluída, entulho '
          '~200 à parte.'),
      _Memo([
        'Cores dos armários, terceira rodada.',
        'Volto sempre ao verde-sálvia, mas o branco-pérola faria a cozinha '
            'parecer maior.',
        'Talvez verde embaixo e branco em cima.',
        'Também ficou decidido: todos os eletrodomésticos ficam menos o '
            'forno, esse já era.',
      ], 'A cor dos armários está entre verde-sálvia e branco-pérola, '
          'talvez combinados. Tudo fica menos o forno.'),
    ],
  ),
  _Loc(
    'ru',
    'Ремонт кухни',
    'Ремонт кухни продвигается: замеры сделаны, смета от подрядчика будет '
        'в четверг, а цвет шкафов выбирается между шалфейно-зелёным и '
        'молочно-белым. Вся техника остаётся, кроме духовки.',
    [
      _Memo([
        'Сегодня утром обмерил всю кухню.',
        'Стена с окном — три метра двадцать, столешница — два сорок, на '
            'холодильник остаётся семьдесят сантиметров.',
        'Важно не забыть: слева выступает труба от батареи, так что в '
            'угловом шкафу нужен вырез.',
      ], 'Кухня обмерена; в угловом шкафу нужен вырез под трубу.'),
      _Memo([
        'Звонил Хансону насчёт сметы.',
        'Он может начать во вторую неделю следующего месяца, а полная '
            'сумма будет к четвергу.',
        'Демонтаж входит в цену, но вывоз мусора отдельно, примерно двести.',
      ], 'Хансон может начать во вторую неделю следующего месяца; полная '
          'смета будет в четверг. Демонтаж включён, вывоз ~200 отдельно.'),
      _Memo([
        'Цвет шкафов, третий заход.',
        'Всё время возвращаюсь к шалфейно-зелёному, но с молочно-белым '
            'комната казалась бы больше.',
        'Может, снизу зелёный, сверху белый.',
        'Ещё решил: вся техника остаётся, кроме духовки, она своё '
            'отслужила.',
      ], 'Цвет шкафов: шалфейно-зелёный или молочно-белый, возможно, '
          'вместе. Техника остаётся, кроме духовки.'),
    ],
  ),
  _Loc(
    'tr',
    'Mutfak tadilatı',
    'Mutfak tadilatı ilerliyor: ölçümler tamam, ustanın teklifi perşembe '
        'günü geliyor ve dolap rengi adaçayı yeşili ile kırık beyaz '
        'arasında. Fırın dışında bütün beyaz eşyalar kalıyor.',
    [
      _Memo([
        'Bu sabah bütün mutfağı ölçtüm.',
        'Pencere duvarı üç metre yirmi, tezgah iki kırk; buzdolabına yetmiş '
            'santim kalıyor.',
        'Unutma: solda kalorifer borusu çıkıntı yapıyor, köşe dolabına '
            'kesim gerekecek.',
      ], 'Mutfak ölçüldü; köşe dolabına boru için kesim gerekiyor.'),
      _Memo([
        'Teklif için Hanson\'ı aradım.',
        'Gelecek ayın ikinci haftası başlayabiliyormuş, kesin rakam '
            'perşembeye kadar gelecek.',
        'Yıkım dahil ama moloz taşıma ekstra, aşağı yukarı iki yüz.',
      ], 'Hanson gelecek ayın ikinci haftası başlayabilir; tam teklif '
          'perşembe geliyor. Yıkım dahil, moloz ~200 ekstra.'),
      _Memo([
        'Dolap renkleri, üçüncü tur.',
        'Hep adaçayı yeşiline dönüyorum ama kırık beyaz odayı daha büyük '
            'gösterir.',
        'Belki altta yeşil, üstte beyaz.',
        'Bir de fırın hariç bütün eşyaların kalmasına karar verdim, fırın '
            'artık bitmiş.',
      ], 'Dolap rengi adaçayı yeşili ile kırık beyaz arasında, belki ikisi '
          'birden. Fırın hariç her şey kalıyor.'),
    ],
  ),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (Platform.isLinux) {
      JustAudioMediaKit.ensureInitialized(
        linux: true,
        windows: false,
        libmpv: Platform.environment['LIBMPV_PATH'],
      );
    }
    final base = Platform.environment['DIKTAFON_TEST_DIR'];
    if (base != null) {
      _workDir = Directory(base);
      if (_workDir.existsSync()) _workDir.deleteSync(recursive: true);
      _workDir.createSync(recursive: true);
    } else {
      _workDir = Directory.systemTemp.createTempSync('diktafon_lang_');
    }
    // One real (tone) file the tape player can load, copied per memo.
    _toneFile = File('${_workDir.path}/tone.m4a');
    final r = await Process.run('ffmpeg', [
      '-y', '-f', 'lavfi', '-i', 'sine=frequency=330:duration=2',
      '-ar', '16000', '-ac', '1', _toneFile.path,
    ]);
    expect(r.exitCode, 0, reason: 'ffmpeg: ${r.stderr}');
  });

  for (final loc in _locales) {
    testWidgets('kitchen cassette screenshot in ${loc.code}', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.localesTestValue = [Locale(loc.code)];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      final dir = Directory('${_workDir.path}/${loc.code}')
        ..createSync(recursive: true);
      final db = AppDatabase.forTesting(
          NativeDatabase(File('${dir.path}/diktafon.db')));
      final audioDir = Directory('${dir.path}/audio')..createSync();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioFileStoreProvider.overrideWithValue(AudioFileStore(audioDir)),
        whisperModelManagerProvider.overrideWithValue(WhisperModelManager(
            Directory('${dir.path}/whisper')..createSync())),
        llmModelManagerProvider.overrideWithValue(
            LlmModelManager(Directory('${dir.path}/llm')..createSync())),
      ]);
      addTearDown(container.dispose);

      final settings = container.read(settingsRepositoryProvider);
      await settings.setTheme('light');
      await db
          .into(db.settingsEntries)
          .insert(const SettingRow(key: 'firstRunDone', value: '1'));

      // — Same anchoring as the store shots: a fixed afternoon —
      final today = DateTime.now();
      final now = DateTime(today.year, today.month, today.day, 17, 45);
      int ago({int days = 0, int hours = 0, int minutes = 0}) => now
          .subtract(Duration(days: days, hours: hours, minutes: minutes))
          .millisecondsSinceEpoch;
      final createdAts = [
        ago(days: 3, hours: 2),
        ago(days: 2, hours: 5),
        ago(minutes: 20),
      ];

      await db.into(db.cassettes).insert(CassetteRow(
            id: 'c-kitchen',
            label: loc.label,
            titleIsUserSet: true,
            colorSeed: 3,
            summary: loc.summary,
            summaryUpdatedAt: ago(minutes: 20),
            createdAt: ago(days: 4),
            updatedAt: ago(minutes: 20),
          ));
      final kitchenAudio = Directory('${audioDir.path}/c-kitchen')
        ..createSync(recursive: true);
      for (final (i, memo) in loc.memos.indexed) {
        final transcript = _transcript(loc.code, memo.sentences);
        final path = '${kitchenAudio.path}/m-$i.m4a';
        _toneFile.copySync(path);
        await db.into(db.memos).insert(MemoRow(
              id: 'm-$i',
              cassetteId: 'c-kitchen',
              filePath: path,
              durationMs: transcript.segments.last.endMs + 700,
              createdAt: createdAts[i],
              detectedLang: loc.code,
              transcript: jsonEncode(transcript.toJson()),
              memoSummary: memo.gist,
              status: 'ready',
            ));
      }

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(key: _boundaryKey, child: const DiktafonApp()),
      ));
      await _settle(tester);

      // Open the cassette (the card paints its label — found via semantics
      // "{label}, {memos}") and park the playhead mid-tape like 02-cassette.
      await tester
          .tap(find.bySemanticsLabel(RegExp('^${RegExp.escape(loc.label)},')));
      await _settle(tester);
      // The collapsed summary Text holds the full string (store test relies
      // on this too) — a robust in-language probe; transcript words may be
      // lazily unbuilt off-screen.
      expect(find.textContaining(loc.summary.split(' ').take(3).join(' ')),
          findsWidgets,
          reason: 'the ${loc.code} summary must be on screen');
      final player = container.read(tapePlayerProvider);
      expect(player.tape.totalDurationMs, greaterThan(0));
      await player.seekGlobal((player.tape.totalDurationMs * 0.55).round());
      await _settle(tester);
      await _shot(tester, loc.code);
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}
