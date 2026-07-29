// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get untitledCassette => 'Cassetta senza titolo';

  @override
  String get rename => 'Rinomina';

  @override
  String get delete => 'Elimina';

  @override
  String get cancel => 'ANNULLA';

  @override
  String get save => 'SALVA';

  @override
  String get deleteAction => 'ELIMINA';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Indietro';

  @override
  String get settingsTooltip => 'Impostazioni';

  @override
  String get homeEmpty =>
      'Ancora nessuna cassetta.\nPremi + per iniziare un nuovo nastro.';

  @override
  String get newCassette => 'Nuova cassetta';

  @override
  String get renameCassetteTitle => 'RINOMINA CASSETTA';

  @override
  String get cassetteNameHint => 'Nome della cassetta';

  @override
  String get deleteCassetteTitle => 'ELIMINARE LA CASSETTA?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count memo',
      one: '1 memo',
    );
    return '«$label» e $_temp0 verranno eliminati. Questa operazione non può essere annullata.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count memo',
      one: '1 memo',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'vuota · premi per aprire';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · cerca un nome…';
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
    return 'oggi $time';
  }

  @override
  String get yesterday => 'ieri';

  @override
  String get deleteCassette => 'Elimina cassetta';

  @override
  String get blankTape =>
      'Un nastro vergine.\nPremi il tasto rosso per registrare.';

  @override
  String get emptyTape => 'NASTRO VUOTO';

  @override
  String memoCounter(int n, int total) {
    return 'MEMO $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'REGISTRAZIONE MEMO $n';
  }

  @override
  String get summaryPlaceholder =>
      'Il riassunto della cassetta appare una volta trascritti i memo.';

  @override
  String get back15 => 'Indietro di 15 secondi';

  @override
  String get forward15 => 'Avanti di 15 secondi';

  @override
  String get play => 'Riproduci';

  @override
  String get pause => 'Pausa';

  @override
  String get recordNewMemo => 'Registra un nuovo memo';

  @override
  String get stopRecording => 'Interrompi la registrazione';

  @override
  String get micPermissionNeeded =>
      'Per registrare serve il permesso del microfono.';

  @override
  String get recordingFailed =>
      'Impossibile avviare la registrazione: il microfono potrebbe essere in uso.';

  @override
  String get playbackError =>
      'Riproduzione non riuscita: il file audio potrebbe mancare o essere danneggiato.';

  @override
  String missingAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Manca l\'audio di $count memo su questo dispositivo.',
      one: 'Manca l\'audio di 1 memo su questo dispositivo.',
    );
    return '$_temp0';
  }

  @override
  String get deleteMemoTitle => 'ELIMINARE IL MEMO?';

  @override
  String deleteMemoBody(int n) {
    return 'Il memo $n verrà rimosso e il nastro si richiuderà senza lasciare vuoti. Questa operazione non può essere annullata.';
  }

  @override
  String get timelineLabel => 'Linea temporale del nastro';

  @override
  String timelinePosition(String position, String total) {
    return '$position di $total';
  }

  @override
  String get noSpeech => '(nessun parlato)';

  @override
  String get transcriptionFailedRetry =>
      'trascrizione non riuscita — tocca per riprovare (l\'audio si può comunque ascoltare)';

  @override
  String get queuedForTranscription => 'in coda per la trascrizione…';

  @override
  String get waitingForModel =>
      'in attesa del modello di trascrizione — scaricalo nelle Impostazioni';

  @override
  String memoDivider(int n, String date) {
    return 'Memo $n — $date';
  }

  @override
  String get summarizing => 'riassunto in corso…';

  @override
  String get summaryFailedRetry =>
      'riassunto non riuscito — tocca per riprovare';

  @override
  String get transcribing => 'trascrizione in corso…';

  @override
  String get settingsTitle => 'IMPOSTAZIONI';

  @override
  String get groupLanguage => 'Lingua';

  @override
  String get transcriptionLanguage => 'Lingua di trascrizione';

  @override
  String get autoDetectValue =>
      'Automatica — ogni memo mantiene la propria lingua';

  @override
  String get autoDetectOption => 'Rilevamento automatico (per ogni memo)';

  @override
  String get transcriptionLanguageTitle => 'LINGUA DI TRASCRIZIONE';

  @override
  String get groupPlayback => 'Riproduzione';

  @override
  String get boundaryChime => 'Segnale tra i memo';

  @override
  String get boundaryChimeDesc =>
      'Un suono delicato quando il nastro passa al memo successivo. Spento = totalmente continuo.';

  @override
  String get groupIntelligence => 'Intelligenza sul dispositivo';

  @override
  String get transcriptionModel => 'Modello di trascrizione';

  @override
  String get summaryModel => 'Modello di riassunto';

  @override
  String get summariesOffOption => 'Nessun riassunto';

  @override
  String get summariesOffDesc =>
      'I memo vengono solo trascritti — niente sintesi, panoramiche o titoli suggeriti.';

  @override
  String get whisperSmallDesc =>
      'Consigliato — il miglior equilibrio tra dimensioni e qualità.';

  @override
  String get whisperSmallDescCapable =>
      'Più leggero e veloce — meno preciso, soprattutto con registrazioni rumorose.';

  @override
  String get whisperLargeDesc =>
      'Precisione più alta; richiede un dispositivo potente (~2,5 GB di RAM mentre trascrive).';

  @override
  String get whisperLargeDescCapable =>
      'Consigliato — molto più preciso, soprattutto in presenza di rumore (~2,5 GB di RAM mentre trascrive).';

  @override
  String get llmDefaultDesc => 'Consigliato — riassunti multilingue compatti.';

  @override
  String get llm4bDesc =>
      'Riassunti e titoli di qualità superiore; richiede un dispositivo potente (~3 GB di RAM mentre riassume).';

  @override
  String get summariesOffValue => 'Nessun riassunto · tocca per configurare';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — installato, tocca per gestire';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — scaricamento $pct %';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — download in pausa al $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — non ancora scaricato · tocca per configurare';
  }

  @override
  String get groupAppearance => 'Aspetto';

  @override
  String get themeRow => 'Tema';

  @override
  String get themeTitle => 'TEMA';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get groupYourData => 'I tuoi dati';

  @override
  String get backupExport => 'Esporta e importa';

  @override
  String get backupExportDesc =>
      'Porta con te le tue cassette — audio, trascrizioni e riassunti — o riportale indietro';

  @override
  String get aboutPrivacy => 'Informazioni e privacy';

  @override
  String get aboutPrivacyDesc => 'L\'audio non lascia mai questo dispositivo';

  @override
  String get aboutTitle => 'INFORMAZIONI E PRIVACY';

  @override
  String get aboutBody =>
      'Diktafon ascolta, scrive e riassume direttamente sul tuo telefono.\n\nRegistrazioni, trascrizioni e riassunti non lasciano mai il dispositivo. Niente account, niente cloud e niente analytics. I dati escono solo con un backup o un\'esportazione che avvii tu.';

  @override
  String get aboutOpenSource => 'Diktafon è gratuito e open source:';

  @override
  String get aboutPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get modelPickerTranscriptionTitle => 'MODELLO DI TRASCRIZIONE';

  @override
  String get modelPickerSummaryTitle => 'MODELLO DI RIASSUNTO';

  @override
  String pickerInstalled(String size) {
    return 'installato · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'scaricamento $pct % — tocca per sospendere';
  }

  @override
  String pickerPaused(int pct) {
    return 'in pausa al $pct % — tocca per riprendere';
  }

  @override
  String pickerDownload(String size) {
    return 'scarica · $size';
  }

  @override
  String needsRam(int gb) {
    return 'richiede ≥ $gb GB di RAM';
  }

  @override
  String storageNote(int mb) {
    return 'Funziona solo su questo dispositivo. Spazio occupato dai modelli: $mb MB.';
  }

  @override
  String get deleteModelTooltip => 'Elimina il file del modello';

  @override
  String modelReadyTranscribe(String label) {
    return '$label è pronto — i memo in attesa vengono trascritti.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label è pronto — i memo in attesa vengono riassunti.';
  }

  @override
  String downloadFailed(String label) {
    return 'Il download di $label non è riuscito — controlla la connessione e riprova.';
  }

  @override
  String get firstRunWelcome => 'Benvenuto in Diktafon';

  @override
  String get firstRunIntro =>
      'Ascolta, scrive e riassume direttamente sul tuo telefono. Registrazioni, trascrizioni e riassunti **non lasciano mai questo dispositivo**. Niente account e niente cloud.';

  @override
  String get firstRunSetupHeader => 'Configurazione iniziale';

  @override
  String get allowMicRow => 'Consenti il microfono';

  @override
  String get micTapToGrant => 'Tocca per consentire l\'accesso';

  @override
  String get rowMicrophone => 'Microfono';

  @override
  String get accessGranted => 'Accesso consentito';

  @override
  String get micDeniedRetry =>
      'Non consentito — tocca per chiedere di nuovo, oppure consenti il microfono nelle impostazioni di sistema';

  @override
  String get rowTranscription => 'Trascrizione';

  @override
  String get rowSummaries => 'Riassunti';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · pronto';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · scaricamento — $pct %';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · in pausa — $pct %';
  }

  @override
  String get provisionChoose => 'tocca per scegliere un modello da scaricare';

  @override
  String get downloadsFinishInBackground =>
      'I download si completano in background.';

  @override
  String get startRecordingKey => 'INIZIA A REGISTRARE';

  @override
  String get backupTitle => 'ESPORTA E IMPORTA';

  @override
  String get backupIntro =>
      'Il backup del dispositivo copre già in automatico l\'elenco delle cassette, le trascrizioni e i riassunti. Le registrazioni audio invece sono pesanti — portale con te esplicitamente: l\'esportazione raccoglie audio, trascrizioni e riassunti di una cassetta in un unico archivio .zip, e importando l\'archivio li riporti indietro. Diktafon non carica nulla online.';

  @override
  String get groupExport => 'Esporta';

  @override
  String get exportAll => 'Esporta tutte le cassette';

  @override
  String get exportAllDesc => 'Tutto, in un unico archivio';

  @override
  String get exporting => 'Esportazione in corso…';

  @override
  String exportedTo(String path) {
    return 'Esportato in $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Esportate $count cassette in $path.',
      one: 'Esportata 1 cassetta in $path.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String get groupImport => 'Importa';

  @override
  String get importArchive => 'Importa un archivio';

  @override
  String get importArchiveDesc =>
      'Aggiungi cassette da un\'esportazione precedente';

  @override
  String get importing => 'Importazione in corso…';

  @override
  String get importDialogTitle => 'IMPORTARE LE CASSETTE?';

  @override
  String get importDialogBody =>
      'Le cassette dell\'archivio vengono aggiunte accanto a quelle che hai già — niente viene eliminato o modificato. Importare una cassetta già presente crea una seconda copia, che puoi eliminare a mano. I memo senza trascrizione o riassunto vengono elaborati dopo l\'importazione.';

  @override
  String get importAction => 'IMPORTA';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos memo',
      one: '1 memo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos memo',
      one: '1 memo',
    );
    String _temp2 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: 'Importate $cassettes cassette con $_temp0.',
      one: 'Importata 1 cassetta con $_temp1.',
    );
    return '$_temp2';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Impossibile importare $count cassette.',
      one: 'Impossibile importare 1 cassetta.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound =>
      'Nessuna cassetta trovata in quell\'archivio.';

  @override
  String importFailed(String error) {
    return 'Importazione non riuscita: $error';
  }

  @override
  String exportNote(String date) {
    return 'Esportato da Diktafon il $date.';
  }

  @override
  String get exportSummaryHeading => 'Riassunto';

  @override
  String get exportNotTranscribed => '(non trascritto)';

  @override
  String get openSystemSettings => 'IMPOSTAZIONI';

  @override
  String get changeColor => 'Cambia colore';

  @override
  String get retranscribe => 'Trascrivi di nuovo';

  @override
  String get retranscribeTitle => 'TRASCRIVERE DI NUOVO LA CASSETTA?';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tutti i $count memo verranno trascritti di nuovo',
      one: 'Il memo verrà trascritto di nuovo',
    );
    return '$_temp0 con i modelli attuali e il riassunto verrà ricostruito. Le trascrizioni e i riassunti esistenti verranno sostituiti, incluse le correzioni manuali. Può volerci un po\' di tempo.';
  }

  @override
  String get retranscribeAction => 'TRASCRIVI';

  @override
  String get colorPickerTitle => 'COLORE DELLA CASSETTA';

  @override
  String colorSwatch(int n) {
    return 'Colore $n';
  }

  @override
  String get copyTranscript => 'Copia trascrizione';

  @override
  String get editTranscript => 'Modifica trascrizione';

  @override
  String get editTranscriptTitle => 'MODIFICA TRASCRIZIONE';

  @override
  String get transcriptCopied => 'Trascrizione copiata.';

  @override
  String get deleteMemo => 'Elimina memo';

  @override
  String get memoActions => 'Azioni del memo';

  @override
  String notifDownloading(String label) {
    return 'Scaricamento di $label';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label installato';
  }
}
