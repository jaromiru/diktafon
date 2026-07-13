// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get untitledCassette => 'Cassette sans titre';

  @override
  String get rename => 'Renommer';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'ANNULER';

  @override
  String get save => 'ENREGISTRER';

  @override
  String get deleteAction => 'SUPPRIMER';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Retour';

  @override
  String get settingsTooltip => 'Réglages';

  @override
  String get homeEmpty =>
      'Pas encore de cassette.\nAppuyez sur + pour démarrer une bande.';

  @override
  String get newCassette => 'Nouvelle cassette';

  @override
  String get renameCassetteTitle => 'RENOMMER LA CASSETTE';

  @override
  String get cassetteNameHint => 'Nom de la cassette';

  @override
  String get deleteCassetteTitle => 'SUPPRIMER LA CASSETTE ?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ses $count mémos',
      one: 'son $count mémo',
    );
    return '« $label » et $_temp0 seront supprimés. C\'est irréversible.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mémos',
      one: '$count mémo',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'vide · appuyez pour ouvrir';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · se nomme…';
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
    return 'aujourd\'hui $time';
  }

  @override
  String get yesterday => 'hier';

  @override
  String get deleteCassette => 'Supprimer la cassette';

  @override
  String get blankTape =>
      'Une bande vierge.\nAppuyez sur la touche rouge pour enregistrer.';

  @override
  String get emptyTape => 'BANDE VIDE';

  @override
  String memoCounter(int n, int total) {
    return 'MÉMO $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'ENREGISTREMENT MÉMO $n';
  }

  @override
  String get summaryPlaceholder =>
      'Le résumé de la cassette apparaît une fois les mémos transcrits.';

  @override
  String get back15 => 'Reculer de 15 secondes';

  @override
  String get forward15 => 'Avancer de 15 secondes';

  @override
  String get play => 'Lecture';

  @override
  String get pause => 'Pause';

  @override
  String get recordNewMemo => 'Enregistrer un nouveau mémo';

  @override
  String get stopRecording => 'Arrêter l\'enregistrement';

  @override
  String get micPermissionNeeded =>
      'L\'accès au micro est nécessaire pour enregistrer.';

  @override
  String get deleteMemoTitle => 'SUPPRIMER LE MÉMO ?';

  @override
  String deleteMemoBody(int n) {
    return 'Le mémo $n sera retiré et la bande se resserre. C\'est irréversible.';
  }

  @override
  String get timelineLabel => 'Chronologie de la bande';

  @override
  String timelinePosition(String position, String total) {
    return '$position sur $total';
  }

  @override
  String get noSpeech => '(pas de parole)';

  @override
  String get transcriptionFailedRetry =>
      'transcription échouée — touchez pour réessayer (le son se lit toujours)';

  @override
  String get queuedForTranscription => 'en attente de transcription…';

  @override
  String get waitingForModel =>
      'en attente du modèle de transcription — téléchargez-le dans les Réglages';

  @override
  String memoDivider(int n, String date) {
    return 'Mémo $n — $date';
  }

  @override
  String get summarizing => 'résumé en cours…';

  @override
  String get summaryFailedRetry => 'résumé échoué — touchez pour réessayer';

  @override
  String get transcribing => 'transcription en cours…';

  @override
  String get settingsTitle => 'RÉGLAGES';

  @override
  String get groupLanguage => 'Langue';

  @override
  String get transcriptionLanguage => 'Langue de transcription';

  @override
  String get autoDetectValue => 'Auto — chaque mémo garde sa propre langue';

  @override
  String get autoDetectOption => 'Détection automatique (par mémo)';

  @override
  String get transcriptionLanguageTitle => 'LANGUE DE TRANSCRIPTION';

  @override
  String get groupPlayback => 'Lecture';

  @override
  String get boundaryChime => 'Carillon de transition';

  @override
  String get boundaryChimeDesc =>
      'Un léger signal quand la bande passe au mémo suivant. Désactivé = parfaitement fluide.';

  @override
  String get groupIntelligence => 'Intelligence sur l\'appareil';

  @override
  String get transcriptionModel => 'Modèle de transcription';

  @override
  String get summaryModel => 'Modèle de résumé';

  @override
  String get summariesRow => 'Résumés';

  @override
  String get summariesRowDesc =>
      'L\'essentiel des mémos et de chaque cassette, généré localement';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — installé, touchez pour gérer';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — téléchargement $pct %';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — téléchargement suspendu à $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — pas encore téléchargé · touchez pour configurer';
  }

  @override
  String get groupAppearance => 'Apparence';

  @override
  String get themeRow => 'Thème';

  @override
  String get themeTitle => 'THÈME';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get groupYourData => 'Vos données';

  @override
  String get backupExport => 'Export et import';

  @override
  String get backupExportDesc =>
      'Emportez vos cassettes — audio, transcriptions et résumés — ou ramenez-les';

  @override
  String get aboutPrivacy => 'À propos & confidentialité';

  @override
  String get aboutPrivacyDesc => 'L\'audio ne quitte jamais cet appareil';

  @override
  String get aboutTitle => 'À PROPOS & CONFIDENTIALITÉ';

  @override
  String get aboutBody =>
      'Diktafon écoute, écrit et résume directement sur votre téléphone.\n\nEnregistrements, transcriptions et résumés ne quittent jamais l\'appareil. Pas de compte, pas de cloud, pas de statistiques. Les données ne sortent que par une sauvegarde ou un export que vous lancez vous-même.';

  @override
  String get aboutOpenSource => 'Diktafon est gratuit et open source :';

  @override
  String get aboutPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get modelPickerTranscriptionTitle => 'MODÈLE DE TRANSCRIPTION';

  @override
  String get modelPickerSummaryTitle => 'MODÈLE DE RÉSUMÉ';

  @override
  String pickerInstalled(String size) {
    return 'installé · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'téléchargement $pct % — toucher pour suspendre';
  }

  @override
  String pickerPaused(int pct) {
    return 'suspendu à $pct % — toucher pour reprendre';
  }

  @override
  String pickerDownload(String size) {
    return 'télécharger · $size';
  }

  @override
  String needsRam(int gb) {
    return 'nécessite ≥ $gb Go de RAM';
  }

  @override
  String storageNote(int mb) {
    return 'Fonctionne uniquement sur cet appareil. Espace occupé par les modèles : $mb Mo.';
  }

  @override
  String get deleteModelTooltip => 'Supprimer le fichier du modèle';

  @override
  String modelReadyTranscribe(String label) {
    return '$label est prêt — transcription des mémos en attente.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label est prêt — résumé des mémos en attente.';
  }

  @override
  String downloadFailed(String label) {
    return 'Le téléchargement de $label a échoué — vérifiez votre connexion et réessayez.';
  }

  @override
  String get firstRunWelcome => 'Bienvenue dans Diktafon';

  @override
  String get firstRunIntro =>
      'Il écoute, écrit et résume directement sur votre téléphone. Enregistrements, transcriptions et résumés **ne quittent jamais cet appareil**. Pas de compte, pas de cloud.';

  @override
  String get firstRunSetupHeader => 'Configuration initiale';

  @override
  String get allowMicRow => 'Autoriser le micro';

  @override
  String get micTapToGrant => 'Touchez pour accorder l\'accès';

  @override
  String get rowMicrophone => 'Micro';

  @override
  String get accessGranted => 'Accès accordé';

  @override
  String get micDeniedRetry =>
      'Pas accordé — touchez pour redemander, ou autorisez le micro dans les réglages du système';

  @override
  String get rowTranscription => 'Transcription';

  @override
  String get rowSummaries => 'Résumés';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · prêt';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · téléchargement — $pct %';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · suspendu — $pct %';
  }

  @override
  String get provisionChoose => 'touchez pour choisir un modèle à télécharger';

  @override
  String get downloadsFinishInBackground =>
      'Les téléchargements se terminent en arrière-plan.';

  @override
  String get startRecordingKey => 'ENREGISTRER';

  @override
  String get backupTitle => 'EXPORT ET IMPORT';

  @override
  String get backupIntro =>
      'La sauvegarde de votre appareil couvre automatiquement la liste des cassettes, les transcriptions et les résumés. L\'audio est volumineux — emportez-le explicitement : un export regroupe l\'audio, les transcriptions et les résumés d\'une cassette dans une archive .zip, et un import les ramène. Diktafon n\'envoie rien.';

  @override
  String get groupExport => 'Export';

  @override
  String get exportAll => 'Exporter toutes les cassettes';

  @override
  String get exportAllDesc => 'Tout, dans une seule archive';

  @override
  String get exporting => 'Export en cours…';

  @override
  String exportedTo(String path) {
    return 'Exporté vers $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cassettes exportées vers $path.',
      one: '$count cassette exportée vers $path.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'Échec de l\'export : $error';
  }

  @override
  String get groupImport => 'Import';

  @override
  String get importArchive => 'Importer une archive';

  @override
  String get importArchiveDesc => 'Ajoute des cassettes d\'un export précédent';

  @override
  String get importing => 'Import en cours…';

  @override
  String get importDialogTitle => 'IMPORTER DES CASSETTES ?';

  @override
  String get importDialogBody =>
      'Les cassettes de l\'archive s\'ajoutent à côté de celles que vous avez — rien n\'est supprimé ni modifié. Importer une cassette déjà présente en crée une seconde copie, que vous pouvez supprimer à la main. Les mémos sans transcription ou résumé sont traités après l\'import.';

  @override
  String get importAction => 'IMPORTER';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos mémos',
      one: '$memos mémo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos mémos',
      one: '$memos mémo',
    );
    String _temp2 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: '$cassettes cassettes importées avec $_temp0.',
      one: '1 cassette importée avec $_temp1.',
    );
    return '$_temp2';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cassettes n\'ont pas pu être importées.',
      one: '1 cassette n\'a pas pu être importée.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound =>
      'Aucune cassette trouvée dans cette archive.';

  @override
  String importFailed(String error) {
    return 'Échec de l\'import : $error';
  }

  @override
  String exportNote(String date) {
    return 'Exporté depuis Diktafon le $date.';
  }

  @override
  String get exportSummaryHeading => 'Résumé';

  @override
  String get exportNotTranscribed => '(non transcrit)';

  @override
  String get openSystemSettings => 'RÉGLAGES';

  @override
  String get changeColor => 'Changer la couleur';

  @override
  String get retranscribe => 'Retranscrire';

  @override
  String get retranscribeTitle => 'RETRANSCRIRE LA CASSETTE ?';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les $count mémos seront retranscrits',
      one: 'Le mémo sera retranscrit',
    );
    return '$_temp0 avec les modèles actuels et le résumé sera reconstruit. Les transcriptions et résumés existants seront remplacés. Cela peut prendre un moment.';
  }

  @override
  String get retranscribeAction => 'RETRANSCRIRE';

  @override
  String get colorPickerTitle => 'COULEUR DE LA CASSETTE';

  @override
  String colorSwatch(int n) {
    return 'Couleur $n';
  }

  @override
  String get copyTranscript => 'Copier la transcription';

  @override
  String get transcriptCopied => 'Transcription copiée.';

  @override
  String get deleteMemo => 'Supprimer le mémo';

  @override
  String get memoActions => 'Actions du mémo';

  @override
  String notifDownloading(String label) {
    return 'Téléchargement de $label';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label installé';
  }
}
