// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get untitledCassette => 'Kaseta bez nazwy';

  @override
  String get rename => 'Zmień nazwę';

  @override
  String get delete => 'Usuń';

  @override
  String get cancel => 'ANULUJ';

  @override
  String get save => 'ZAPISZ';

  @override
  String get deleteAction => 'USUŃ';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Wstecz';

  @override
  String get settingsTooltip => 'Ustawienia';

  @override
  String get homeEmpty =>
      'Nie ma jeszcze kaset.\nNaciśnij +, aby zacząć nową taśmę.';

  @override
  String get newCassette => 'Nowa kaseta';

  @override
  String get renameCassetteTitle => 'ZMIEŃ NAZWĘ KASETY';

  @override
  String get cassetteNameHint => 'Nazwa kasety';

  @override
  String get deleteCassetteTitle => 'USUNĄĆ KASETĘ?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nagrania',
      many: '$count nagrań',
      few: '$count nagrania',
      one: '1 nagranie',
    );
    return '„$label” i $_temp0 zostaną usunięte. Tego nie da się cofnąć.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nagrania',
      many: '$count nagrań',
      few: '$count nagrania',
      one: '1 nagranie',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'pusta · naciśnij, aby otworzyć';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · sama się nazywa…';
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
    return 'dziś $time';
  }

  @override
  String get yesterday => 'wczoraj';

  @override
  String get deleteCassette => 'Usuń kasetę';

  @override
  String get blankTape =>
      'Czysta taśma.\nNaciśnij czerwony klawisz, aby nagrywać.';

  @override
  String get emptyTape => 'PUSTA TAŚMA';

  @override
  String memoCounter(int n, int total) {
    return 'NAGRANIE $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'TRWA NAGRANIE $n';
  }

  @override
  String get summaryPlaceholder =>
      'Podsumowanie kasety pojawi się po transkrypcji nagrań.';

  @override
  String get back15 => '15 sekund wstecz';

  @override
  String get forward15 => '15 sekund naprzód';

  @override
  String get play => 'Odtwórz';

  @override
  String get pause => 'Wstrzymaj';

  @override
  String get recordNewMemo => 'Nagraj nowe nagranie';

  @override
  String get stopRecording => 'Zatrzymaj nagrywanie';

  @override
  String get micPermissionNeeded =>
      'Do nagrywania potrzebny jest dostęp do mikrofonu.';

  @override
  String get deleteMemoTitle => 'USUNĄĆ NAGRANIE?';

  @override
  String deleteMemoBody(int n) {
    return 'Nagranie $n zostanie usunięte, a taśma się domknie. Tego nie da się cofnąć.';
  }

  @override
  String get timelineLabel => 'Oś taśmy';

  @override
  String timelinePosition(String position, String total) {
    return '$position z $total';
  }

  @override
  String get noSpeech => '(brak mowy)';

  @override
  String get transcriptionFailedRetry =>
      'transkrypcja nie powiodła się — dotknij, aby ponowić (dźwięk nadal gra)';

  @override
  String get queuedForTranscription => 'w kolejce do transkrypcji…';

  @override
  String get waitingForModel =>
      'czeka na model transkrypcji — pobierz go w Ustawieniach';

  @override
  String memoDivider(int n, String date) {
    return 'Nagranie $n — $date';
  }

  @override
  String get summarizing => 'powstaje podsumowanie…';

  @override
  String get summaryFailedRetry =>
      'podsumowanie nie powiodło się — dotknij, aby ponowić';

  @override
  String get transcribing => 'trwa transkrypcja…';

  @override
  String get settingsTitle => 'USTAWIENIA';

  @override
  String get groupLanguage => 'Język';

  @override
  String get transcriptionLanguage => 'Język transkrypcji';

  @override
  String get autoDetectValue =>
      'Automatycznie — każde nagranie zachowuje swój język';

  @override
  String get autoDetectOption => 'Automatycznie (dla każdego nagrania)';

  @override
  String get transcriptionLanguageTitle => 'JĘZYK TRANSKRYPCJI';

  @override
  String get groupPlayback => 'Odtwarzanie';

  @override
  String get boundaryChime => 'Sygnał między nagraniami';

  @override
  String get boundaryChimeDesc =>
      'Delikatny dźwięk, gdy taśma przechodzi do następnego nagrania. Wyłączony = idealnie płynnie.';

  @override
  String get groupIntelligence => 'Inteligencja na urządzeniu';

  @override
  String get transcriptionModel => 'Model transkrypcji';

  @override
  String get summaryModel => 'Model podsumowań';

  @override
  String get summariesRow => 'Podsumowania';

  @override
  String get summariesRowDesc =>
      'Streszczenia nagrań i przeglądy kaset, tworzone lokalnie';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — zainstalowano, dotknij, aby zarządzać';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — pobieranie $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — jeszcze nie pobrano · dotknij, aby skonfigurować';
  }

  @override
  String get groupAppearance => 'Wygląd';

  @override
  String get themeRow => 'Motyw';

  @override
  String get themeTitle => 'MOTYW';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get groupYourData => 'Twoje dane';

  @override
  String get backupExport => 'Eksport danych';

  @override
  String get backupExportDesc =>
      'Zabierz kasety ze sobą — dźwięk, transkrypcje i podsumowania';

  @override
  String get aboutPrivacy => 'O aplikacji i prywatność';

  @override
  String get aboutPrivacyDesc => 'Dźwięk nigdy nie opuszcza tego urządzenia';

  @override
  String get aboutTitle => 'O APLIKACJI I PRYWATNOŚĆ';

  @override
  String get aboutBody =>
      'Diktafon słucha, zapisuje i podsumowuje prosto w Twoim telefonie.\n\nNagrania, transkrypcje i podsumowania nigdy nie opuszczają urządzenia. Nie ma konta, chmury ani analityki. Dane wychodzą tylko przez kopię lub eksport, które uruchamiasz samodzielnie.';

  @override
  String get modelPickerTranscriptionTitle => 'MODEL TRANSKRYPCJI';

  @override
  String get modelPickerSummaryTitle => 'MODEL PODSUMOWAŃ';

  @override
  String pickerInstalled(String size) {
    return 'zainstalowano · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'pobieranie $pct %';
  }

  @override
  String pickerDownload(String size) {
    return 'pobierz · $size';
  }

  @override
  String needsRam(int gb) {
    return 'wymaga ≥ $gb GB RAM';
  }

  @override
  String storageNote(int mb) {
    return 'Działa tylko na tym urządzeniu. Miejsce zajęte przez modele: $mb MB.';
  }

  @override
  String get deleteModelTooltip => 'Usuń plik modelu';

  @override
  String modelReadyTranscribe(String label) {
    return '$label gotowy — transkrybuję czekające nagrania.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label gotowy — podsumowuję czekające nagrania.';
  }

  @override
  String downloadFailed(String label) {
    return 'Pobieranie modelu $label nie powiodło się — sprawdź połączenie i spróbuj ponownie.';
  }

  @override
  String get firstRunWelcome => 'Witaj w Diktafonie';

  @override
  String get firstRunIntro =>
      'Słucha, zapisuje i podsumowuje prosto w Twoim telefonie. Nagrania, transkrypcje i podsumowania **nigdy nie opuszczają tego urządzenia**. Nie ma konta ani chmury.';

  @override
  String get firstRunSetupHeader => 'Konfiguracja początkowa';

  @override
  String get allowMicRow => 'Zezwól na mikrofon';

  @override
  String get micTapToGrant => 'Dotknij, aby przyznać dostęp';

  @override
  String get rowMicrophone => 'Mikrofon';

  @override
  String get accessGranted => 'Dostęp przyznany';

  @override
  String get micDeniedRetry =>
      'Nie przyznano — dotknij, aby zapytać ponownie, albo zezwól na mikrofon w ustawieniach systemu';

  @override
  String get rowTranscription => 'Transkrypcja';

  @override
  String get rowSummaries => 'Podsumowania';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · gotowy';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · pobieranie — $pct %';
  }

  @override
  String get provisionChoose => 'dotknij, aby wybrać model do pobrania';

  @override
  String get downloadsFinishInBackground => 'Pobieranie dokończy się w tle.';

  @override
  String get startRecordingKey => 'ZACZNIJ NAGRYWAĆ';

  @override
  String get backupTitle => 'EKSPORT DANYCH';

  @override
  String get backupIntro =>
      'Kopia zapasowa urządzenia sama obejmuje listę kaset, transkrypcje i podsumowania. Nagrania audio są duże — zabierz je jawnie: eksport zapisuje folder z plikami audio, transkrypcją i podsumowaniami. Diktafon niczego nie wysyła.';

  @override
  String get groupExport => 'Eksport';

  @override
  String get exportAll => 'Eksportuj wszystkie kasety';

  @override
  String get exportAllDesc => 'Wszystko do jednego wybranego folderu';

  @override
  String get exporting => 'Eksportowanie…';

  @override
  String exportedTo(String path) {
    return 'Wyeksportowano do $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wyeksportowano $count kasety do $path.',
      many: 'Wyeksportowano $count kaset do $path.',
      few: 'Wyeksportowano $count kasety do $path.',
      one: 'Wyeksportowano 1 kasetę do $path.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'Eksport nie powiódł się: $error';
  }

  @override
  String get pickLocalFolder =>
      'Do tego folderu nie da się zapisywać bezpośrednio — wybierz folder lokalny.';

  @override
  String exportNote(String date) {
    return 'Wyeksportowano z Diktafonu $date.';
  }

  @override
  String get exportSummaryHeading => 'Podsumowanie';

  @override
  String get exportNotTranscribed => '(bez transkrypcji)';

  @override
  String get openSystemSettings => 'USTAWIENIA';

  @override
  String get changeColor => 'Zmień kolor';

  @override
  String get colorPickerTitle => 'KOLOR KASETY';

  @override
  String colorSwatch(int n) {
    return 'Kolor $n';
  }

  @override
  String get copyTranscript => 'Kopiuj transkrypcję';

  @override
  String get transcriptCopied => 'Skopiowano transkrypcję.';

  @override
  String get deleteMemo => 'Usuń nagranie';

  @override
  String get memoActions => 'Działania nagrania';

  @override
  String get cleanupRow => 'Czyszczenie transkrypcji';

  @override
  String get cleanupRowDesc =>
      'Model streszczeń poprawia świeże transkrypcje — literówki i przesłyszenia';

  @override
  String notifDownloading(String label) {
    return 'Pobieranie: $label';
  }

  @override
  String notifModelInstalled(String label) {
    return 'Zainstalowano $label';
  }
}
