// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get untitledCassette => 'Kazeta bez názvu';

  @override
  String get rename => 'Přejmenovat';

  @override
  String get delete => 'Smazat';

  @override
  String get cancel => 'ZRUŠIT';

  @override
  String get save => 'ULOŽIT';

  @override
  String get deleteAction => 'SMAZAT';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Zpět';

  @override
  String get settingsTooltip => 'Nastavení';

  @override
  String get homeEmpty =>
      'Zatím žádné kazety.\nNovou pásku začnete tlačítkem +.';

  @override
  String get newCassette => 'Nová kazeta';

  @override
  String get renameCassetteTitle => 'PŘEJMENOVAT KAZETU';

  @override
  String get cassetteNameHint => 'Název kazety';

  @override
  String get deleteCassetteTitle => 'SMAZAT KAZETU?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jejích záznamů',
      few: '$count její záznamy',
      one: '1 její záznam',
    );
    return '„$label“ a $_temp0 budou smazány. Tohle nejde vrátit.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count záznamů',
      few: '$count záznamy',
      one: '1 záznam',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'prázdná · otevřete stisknutím';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · pojmenovává se…';
  }

  @override
  String cardMetaUpdated(String memos, String date) {
    return '$memos · $date';
  }

  @override
  String cardSemantics(String label, String memos) {
    return '$label, $memos';
  }

  @override
  String todayAt(String time) {
    return 'dnes $time';
  }

  @override
  String get yesterday => 'včera';

  @override
  String get deleteCassette => 'Smazat kazetu';

  @override
  String get blankTape => 'Prázdná páska.\nNahrávejte červenou klávesou.';

  @override
  String get emptyTape => 'PRÁZDNÁ PÁSKA';

  @override
  String memoCounter(int n, int total) {
    return 'ZÁZNAM $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'NAHRÁVÁ SE ZÁZNAM $n';
  }

  @override
  String get summaryPlaceholder =>
      'Souhrn kazety se objeví, jakmile budou záznamy přepsány.';

  @override
  String get back15 => 'Zpět o 15 sekund';

  @override
  String get forward15 => 'Vpřed o 15 sekund';

  @override
  String get play => 'Přehrát';

  @override
  String get pause => 'Pozastavit';

  @override
  String get recordNewMemo => 'Nahrát nový záznam';

  @override
  String get stopRecording => 'Zastavit nahrávání';

  @override
  String get micPermissionNeeded =>
      'K nahrávání je potřeba přístup k mikrofonu.';

  @override
  String get deleteMemoTitle => 'SMAZAT ZÁZNAM?';

  @override
  String deleteMemoBody(int n) {
    return 'Záznam $n bude odstraněn a páska se spojí. Tohle nejde vrátit.';
  }

  @override
  String get timelineLabel => 'Časová osa pásky';

  @override
  String timelinePosition(String position, String total) {
    return '$position z $total';
  }

  @override
  String get noSpeech => '(žádná řeč)';

  @override
  String get transcriptionFailedRetry =>
      'přepis selhal — klepnutím to zkusíte znovu (zvuk hraje dál)';

  @override
  String get queuedForTranscription => 'čeká na přepis…';

  @override
  String get waitingForModel =>
      'čeká na model přepisu — stáhněte ho v Nastavení';

  @override
  String memoDivider(int n, String date) {
    return 'Záznam $n — $date';
  }

  @override
  String get summarizing => 'vytváří se souhrn…';

  @override
  String get summaryFailedRetry => 'souhrn selhal — klepnutím to zkusíte znovu';

  @override
  String get transcribing => 'přepisuje se…';

  @override
  String get settingsTitle => 'NASTAVENÍ';

  @override
  String get groupLanguage => 'Jazyk';

  @override
  String get transcriptionLanguage => 'Jazyk přepisu';

  @override
  String get autoDetectValue => 'Automaticky — každý záznam si drží svůj jazyk';

  @override
  String get autoDetectOption => 'Automaticky (pro každý záznam)';

  @override
  String get transcriptionLanguageTitle => 'JAZYK PŘEPISU';

  @override
  String get groupPlayback => 'Přehrávání';

  @override
  String get boundaryChime => 'Tón mezi záznamy';

  @override
  String get boundaryChimeDesc =>
      'Jemné cinknutí, když páska přejde do dalšího záznamu. Vypnuto = zcela plynulé.';

  @override
  String get groupIntelligence => 'Inteligence v zařízení';

  @override
  String get transcriptionModel => 'Model přepisu';

  @override
  String get summaryModel => 'Model souhrnů';

  @override
  String get summariesOffOption => 'Bez souhrnů';

  @override
  String get summariesOffDesc =>
      'Záznamy se pouze přepisují — žádná shrnutí, přehledy ani navrhované názvy.';

  @override
  String get whisperSmallDesc =>
      'Doporučený — nejlepší poměr velikosti a kvality.';

  @override
  String get whisperSmallDescCapable =>
      'Menší a rychlejší — méně přesný, zvlášť u hlučných nahrávek.';

  @override
  String get whisperLargeDesc =>
      'Vyšší přesnost; vyžaduje výkonné zařízení (~2,5 GB RAM při přepisu).';

  @override
  String get whisperLargeDescCapable =>
      'Doporučený — výrazně přesnější, zvlášť v hluku (~2,5 GB RAM při přepisu).';

  @override
  String get llmDefaultDesc => 'Doporučený — kompaktní vícejazyčné souhrny.';

  @override
  String get llm4bDesc =>
      'Kvalitnější souhrny a názvy; vyžaduje výkonné zařízení (~3 GB RAM při vytváření souhrnu).';

  @override
  String get summariesOffValue => 'Bez souhrnů · klepnutím nastavíte';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — nainstalováno, klepnutím spravujete';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — stahuje se $pct %';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — stahování pozastaveno na $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — zatím nestaženo · klepnutím nastavíte';
  }

  @override
  String get groupAppearance => 'Vzhled';

  @override
  String get themeRow => 'Motiv';

  @override
  String get themeTitle => 'MOTIV';

  @override
  String get themeSystem => 'Podle systému';

  @override
  String get themeLight => 'Světlý';

  @override
  String get themeDark => 'Tmavý';

  @override
  String get groupYourData => 'Vaše data';

  @override
  String get backupExport => 'Export a import';

  @override
  String get backupExportDesc =>
      'Vezměte si kazety s sebou — zvuk, přepisy i souhrny — nebo je vraťte zpět';

  @override
  String get aboutPrivacy => 'O aplikaci a soukromí';

  @override
  String get aboutPrivacyDesc => 'Zvuk nikdy neopustí toto zařízení';

  @override
  String get aboutTitle => 'O APLIKACI A SOUKROMÍ';

  @override
  String get aboutBody =>
      'Diktafon poslouchá, zapisuje a shrnuje přímo ve vašem telefonu.\n\nNahrávky, přepisy ani souhrny nikdy neopustí zařízení. Žádný účet, žádný cloud, žádná analytika. Data odcházejí jen zálohou nebo exportem, který spustíte sami.';

  @override
  String get aboutOpenSource =>
      'Diktafon je zdarma a s otevřeným zdrojovým kódem:';

  @override
  String get aboutPrivacyPolicy => 'Zásady ochrany soukromí';

  @override
  String get modelPickerTranscriptionTitle => 'MODEL PŘEPISU';

  @override
  String get modelPickerSummaryTitle => 'MODEL SOUHRNŮ';

  @override
  String pickerInstalled(String size) {
    return 'nainstalováno · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'stahuje se $pct % — klepnutím pozastavíte';
  }

  @override
  String pickerPaused(int pct) {
    return 'pozastaveno na $pct % — klepnutím pokračujete';
  }

  @override
  String pickerDownload(String size) {
    return 'stáhnout · $size';
  }

  @override
  String needsRam(int gb) {
    return 'vyžaduje ≥ $gb GB RAM';
  }

  @override
  String storageNote(int mb) {
    return 'Běží jen v tomto zařízení. Úložiště zabrané modely: $mb MB.';
  }

  @override
  String get deleteModelTooltip => 'Smazat soubor modelu';

  @override
  String modelReadyTranscribe(String label) {
    return '$label je připraven — přepisuji čekající záznamy.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label je připraven — shrnuji čekající záznamy.';
  }

  @override
  String downloadFailed(String label) {
    return 'Stažení modelu $label selhalo — zkontrolujte připojení a zkuste to znovu.';
  }

  @override
  String get firstRunWelcome => 'Vítejte v Diktafonu';

  @override
  String get firstRunIntro =>
      'Poslouchá, zapisuje a shrnuje přímo ve vašem telefonu. Nahrávky, přepisy a souhrny **nikdy neopustí toto zařízení**. Žádný účet, žádný cloud.';

  @override
  String get firstRunSetupHeader => 'Počáteční nastavení';

  @override
  String get allowMicRow => 'Povolit mikrofon';

  @override
  String get micTapToGrant => 'Klepnutím povolíte přístup';

  @override
  String get rowMicrophone => 'Mikrofon';

  @override
  String get accessGranted => 'Přístup povolen';

  @override
  String get micDeniedRetry =>
      'Nepovoleno — klepnutím se zeptáte znovu, nebo mikrofon povolte v nastavení systému';

  @override
  String get rowTranscription => 'Přepis';

  @override
  String get rowSummaries => 'Souhrny';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · připraven';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · stahuje se — $pct %';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · pozastaveno — $pct %';
  }

  @override
  String get provisionChoose => 'klepnutím vyberte model ke stažení';

  @override
  String get downloadsFinishInBackground => 'Stahování doběhne na pozadí.';

  @override
  String get startRecordingKey => 'ZAČÍT NAHRÁVAT';

  @override
  String get backupTitle => 'EXPORT A IMPORT';

  @override
  String get backupIntro =>
      'Záloha vašeho zařízení se o seznam kazet, přepisy a souhrny postará automaticky. Nahrávky jsou velké — vezměte si je výslovně: export zabalí zvuk, přepisy a souhrny kazety do jednoho archivu .zip a import archivu je vrátí zpět. Diktafon nic nikam nenahrává.';

  @override
  String get groupExport => 'Export';

  @override
  String get exportAll => 'Exportovat všechny kazety';

  @override
  String get exportAllDesc => 'Všechno do jednoho archivu';

  @override
  String get exporting => 'Exportuji…';

  @override
  String exportedTo(String path) {
    return 'Exportováno do $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Exportováno $count kazet do $path.',
      few: 'Exportovány $count kazety do $path.',
      one: 'Exportována 1 kazeta do $path.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'Export selhal: $error';
  }

  @override
  String get groupImport => 'Import';

  @override
  String get importArchive => 'Importovat archiv';

  @override
  String get importArchiveDesc => 'Přidá kazety z dřívějšího exportu';

  @override
  String get importing => 'Importuji…';

  @override
  String get importDialogTitle => 'IMPORTOVAT KAZETY?';

  @override
  String get importDialogBody =>
      'Kazety z archivu se přidají vedle stávajících — nic se nemaže ani nepřepisuje. Importem kazety, kterou už máte, vznikne druhá kopie; tu můžete ručně smazat. Záznamy bez přepisu nebo souhrnu se zpracují po importu.';

  @override
  String get importAction => 'IMPORTOVAT';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos záznamů',
      few: '$memos záznamy',
      one: '1 záznam',
    );
    String _temp1 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos záznamů',
      few: '$memos záznamy',
      one: '1 záznam',
    );
    String _temp2 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos záznamů',
      few: '$memos záznamy',
      one: '1 záznam',
    );
    String _temp3 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: 'Importováno $cassettes kazet a $_temp0.',
      few: 'Importovány $cassettes kazety a $_temp1.',
      one: 'Importována 1 kazeta a $_temp2.',
    );
    return '$_temp3';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kazet se nepodařilo importovat.',
      few: '$count kazety se nepodařilo importovat.',
      one: '1 kazetu se nepodařilo importovat.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound => 'V tomto archivu žádné kazety nejsou.';

  @override
  String importFailed(String error) {
    return 'Import selhal: $error';
  }

  @override
  String exportNote(String date) {
    return 'Exportováno z Diktafonu $date.';
  }

  @override
  String get exportSummaryHeading => 'Souhrn';

  @override
  String get exportNotTranscribed => '(bez přepisu)';

  @override
  String get openSystemSettings => 'NASTAVENÍ';

  @override
  String get changeColor => 'Změnit barvu';

  @override
  String get retranscribe => 'Přepsat znovu';

  @override
  String get retranscribeTitle => 'PŘEPSAT KAZETU ZNOVU?';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Všech $count záznamů se přepíše',
      few: 'Všechny $count záznamy se přepíšou',
      one: 'Záznam se přepíše',
    );
    return '$_temp0 znovu aktuálními modely a shrnutí se sestaví nanovo. Stávající přepisy a shrnutí budou nahrazeny. Může to chvíli trvat.';
  }

  @override
  String get retranscribeAction => 'PŘEPSAT';

  @override
  String get colorPickerTitle => 'BARVA KAZETY';

  @override
  String colorSwatch(int n) {
    return 'Barva $n';
  }

  @override
  String get copyTranscript => 'Kopírovat přepis';

  @override
  String get transcriptCopied => 'Přepis zkopírován.';

  @override
  String get deleteMemo => 'Smazat záznam';

  @override
  String get memoActions => 'Akce záznamu';

  @override
  String notifDownloading(String label) {
    return 'Stahuje se $label';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label — nainstalováno';
  }
}
