// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get untitledCassette => 'Unbenannte Kassette';

  @override
  String get rename => 'Umbenennen';

  @override
  String get delete => 'Löschen';

  @override
  String get cancel => 'ABBRECHEN';

  @override
  String get save => 'SPEICHERN';

  @override
  String get deleteAction => 'LÖSCHEN';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Zurück';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String get homeEmpty =>
      'Noch keine Kassetten.\nMit + beginnt ein neues Band.';

  @override
  String get newCassette => 'Neue Kassette';

  @override
  String get renameCassetteTitle => 'KASSETTE UMBENENNEN';

  @override
  String get cassetteNameHint => 'Name der Kassette';

  @override
  String get deleteCassetteTitle => 'KASSETTE LÖSCHEN?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Memos',
      one: '1 Memo',
    );
    return '„$label“ und $_temp0 werden gelöscht. Das lässt sich nicht rückgängig machen.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Memos',
      one: '1 Memo',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'leer · zum Öffnen drücken';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · benennt sich…';
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
    return 'heute $time';
  }

  @override
  String get yesterday => 'gestern';

  @override
  String get deleteCassette => 'Kassette löschen';

  @override
  String get blankTape =>
      'Ein leeres Band.\nZum Aufnehmen die rote Taste drücken.';

  @override
  String get emptyTape => 'LEERES BAND';

  @override
  String memoCounter(int n, int total) {
    return 'MEMO $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'AUFNAHME MEMO $n';
  }

  @override
  String get summaryPlaceholder =>
      'Die Kassetten-Zusammenfassung erscheint, sobald Memos transkribiert sind.';

  @override
  String get back15 => '15 Sekunden zurück';

  @override
  String get forward15 => '15 Sekunden vor';

  @override
  String get play => 'Wiedergabe';

  @override
  String get pause => 'Pause';

  @override
  String get recordNewMemo => 'Neues Memo aufnehmen';

  @override
  String get stopRecording => 'Aufnahme stoppen';

  @override
  String get micPermissionNeeded =>
      'Zum Aufnehmen wird der Mikrofonzugriff benötigt.';

  @override
  String get deleteMemoTitle => 'MEMO LÖSCHEN?';

  @override
  String deleteMemoBody(int n) {
    return 'Memo $n wird entfernt und das Band schließt die Lücke. Das lässt sich nicht rückgängig machen.';
  }

  @override
  String get timelineLabel => 'Bandzeitleiste';

  @override
  String timelinePosition(String position, String total) {
    return '$position von $total';
  }

  @override
  String get noSpeech => '(keine Sprache)';

  @override
  String get transcriptionFailedRetry =>
      'Transkription fehlgeschlagen — zum Wiederholen tippen (der Ton spielt weiter)';

  @override
  String get queuedForTranscription => 'wartet auf Transkription…';

  @override
  String get waitingForModel =>
      'wartet auf das Transkriptionsmodell — in den Einstellungen herunterladen';

  @override
  String memoDivider(int n, String date) {
    return 'Memo $n — $date';
  }

  @override
  String get summarizing => 'wird zusammengefasst…';

  @override
  String get summaryFailedRetry =>
      'Zusammenfassung fehlgeschlagen — zum Wiederholen tippen';

  @override
  String get transcribing => 'wird transkribiert…';

  @override
  String get settingsTitle => 'EINSTELLUNGEN';

  @override
  String get groupLanguage => 'Sprache';

  @override
  String get transcriptionLanguage => 'Transkriptionssprache';

  @override
  String get autoDetectValue =>
      'Automatisch — jedes Memo behält seine eigene Sprache';

  @override
  String get autoDetectOption => 'Automatisch (pro Memo)';

  @override
  String get transcriptionLanguageTitle => 'TRANSKRIPTIONSSPRACHE';

  @override
  String get groupPlayback => 'Wiedergabe';

  @override
  String get boundaryChime => 'Übergangston';

  @override
  String get boundaryChimeDesc =>
      'Ein leiser Hinweis, wenn das Band ins nächste Memo läuft. Aus = völlig nahtlos.';

  @override
  String get groupIntelligence => 'Intelligenz auf dem Gerät';

  @override
  String get transcriptionModel => 'Transkriptionsmodell';

  @override
  String get summaryModel => 'Zusammenfassungsmodell';

  @override
  String get summariesRow => 'Zusammenfassungen';

  @override
  String get summariesRowDesc =>
      'Memo-Kurzfassungen & Kassettenüberblicke, lokal erzeugt';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — installiert, zum Verwalten tippen';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — lädt $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — noch nicht geladen · zum Einrichten tippen';
  }

  @override
  String get groupAppearance => 'Darstellung';

  @override
  String get themeRow => 'Design';

  @override
  String get themeTitle => 'DESIGN';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get groupYourData => 'Deine Daten';

  @override
  String get backupExport => 'Daten exportieren';

  @override
  String get backupExportDesc =>
      'Nimm deine Kassetten mit — Audio, Transkripte und Zusammenfassungen';

  @override
  String get aboutPrivacy => 'Über & Datenschutz';

  @override
  String get aboutPrivacyDesc => 'Audio verlässt dieses Gerät nie';

  @override
  String get aboutTitle => 'ÜBER & DATENSCHUTZ';

  @override
  String get aboutBody =>
      'Diktafon hört zu, schreibt mit und fasst zusammen — direkt auf deinem Telefon.\n\nAufnahmen, Transkripte und Zusammenfassungen verlassen das Gerät nie. Es gibt kein Konto, keine Cloud und keine Analyse. Daten verlassen das Gerät nur über eine Sicherung oder einen Export, den du selbst startest.';

  @override
  String get aboutOpenSource => 'Diktafon ist kostenlos und quelloffen:';

  @override
  String get modelPickerTranscriptionTitle => 'TRANSKRIPTIONSMODELL';

  @override
  String get modelPickerSummaryTitle => 'ZUSAMMENFASSUNGSMODELL';

  @override
  String pickerInstalled(String size) {
    return 'installiert · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'lädt $pct %';
  }

  @override
  String pickerDownload(String size) {
    return 'laden · $size';
  }

  @override
  String needsRam(int gb) {
    return 'braucht ≥ $gb GB RAM';
  }

  @override
  String storageNote(int mb) {
    return 'Läuft nur auf diesem Gerät. Von Modellen belegter Speicher: $mb MB.';
  }

  @override
  String get deleteModelTooltip => 'Modelldatei löschen';

  @override
  String modelReadyTranscribe(String label) {
    return '$label ist bereit — wartende Memos werden transkribiert.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label ist bereit — wartende Memos werden zusammengefasst.';
  }

  @override
  String downloadFailed(String label) {
    return 'Download von $label fehlgeschlagen — Verbindung prüfen und erneut versuchen.';
  }

  @override
  String get firstRunWelcome => 'Willkommen bei Diktafon';

  @override
  String get firstRunIntro =>
      'Es hört zu, schreibt mit und fasst zusammen — direkt auf deinem Telefon. Aufnahmen, Transkripte und Zusammenfassungen **verlassen dieses Gerät nie**. Es gibt kein Konto und keine Cloud.';

  @override
  String get firstRunSetupHeader => 'Ersteinrichtung';

  @override
  String get allowMicRow => 'Mikrofon erlauben';

  @override
  String get micTapToGrant => 'Zum Erlauben tippen';

  @override
  String get rowMicrophone => 'Mikrofon';

  @override
  String get accessGranted => 'Zugriff gewährt';

  @override
  String get micDeniedRetry =>
      'Nicht erlaubt — tippe, um erneut zu fragen, oder erlaube das Mikrofon in den Systemeinstellungen';

  @override
  String get rowTranscription => 'Transkription';

  @override
  String get rowSummaries => 'Zusammenfassungen';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · bereit';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · lädt — $pct %';
  }

  @override
  String get provisionChoose =>
      'tippen, um ein Modell zum Herunterladen zu wählen';

  @override
  String get downloadsFinishInBackground =>
      'Downloads laufen im Hintergrund weiter.';

  @override
  String get startRecordingKey => 'AUFNAHME STARTEN';

  @override
  String get backupTitle => 'DATEN EXPORTIEREN';

  @override
  String get backupIntro =>
      'Die Sicherung deines Geräts erfasst Kassettenliste, Transkripte und Zusammenfassungen automatisch. Audioaufnahmen sind groß — nimm sie ausdrücklich mit: ein Export schreibt einen Ordner mit den Audiodateien, dem Transkript und den Zusammenfassungen. Diktafon lädt nichts hoch.';

  @override
  String get groupExport => 'Export';

  @override
  String get exportAll => 'Alle Kassetten exportieren';

  @override
  String get exportAllDesc => 'Alles in einen Ordner deiner Wahl';

  @override
  String get exporting => 'Exportiere…';

  @override
  String exportedTo(String path) {
    return 'Exportiert nach $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kassetten nach $path exportiert.',
      one: '1 Kassette nach $path exportiert.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get pickLocalFolder =>
      'In diesen Ordner kann nicht direkt geschrieben werden — wähle einen lokalen Ordner.';

  @override
  String exportNote(String date) {
    return 'Exportiert aus Diktafon am $date.';
  }

  @override
  String get exportSummaryHeading => 'Zusammenfassung';

  @override
  String get exportNotTranscribed => '(nicht transkribiert)';

  @override
  String get openSystemSettings => 'EINSTELLUNGEN';

  @override
  String get changeColor => 'Farbe ändern';

  @override
  String get retranscribe => 'Neu transkribieren';

  @override
  String get retranscribeTitle => 'KASSETTE NEU TRANSKRIBIEREN?';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Memos werden',
      one: 'Das Memo wird',
    );
    return '$_temp0 mit den aktuellen Modellen neu transkribiert und die Zusammenfassung wird neu erstellt. Bestehende Transkripte und Zusammenfassungen werden ersetzt. Das kann eine Weile dauern.';
  }

  @override
  String get retranscribeAction => 'NEU TRANSKRIBIEREN';

  @override
  String get colorPickerTitle => 'KASSETTENFARBE';

  @override
  String colorSwatch(int n) {
    return 'Farbe $n';
  }

  @override
  String get copyTranscript => 'Transkript kopieren';

  @override
  String get transcriptCopied => 'Transkript kopiert.';

  @override
  String get deleteMemo => 'Memo löschen';

  @override
  String get memoActions => 'Memo-Aktionen';

  @override
  String get cleanupRow => 'Transkript-Korrektur';

  @override
  String get cleanupRowDesc =>
      'Das Zusammenfassungsmodell glättet frische Transkripte — Tipp- und Hörfehler';

  @override
  String notifDownloading(String label) {
    return '$label wird heruntergeladen';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label installiert';
  }
}
