// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get untitledCassette => 'Untitled cassette';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'CANCEL';

  @override
  String get save => 'SAVE';

  @override
  String get deleteAction => 'DELETE';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Back';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get homeEmpty => 'No cassettes yet.\nPress + to start a new tape.';

  @override
  String get newCassette => 'New cassette';

  @override
  String get renameCassetteTitle => 'RENAME CASSETTE';

  @override
  String get cassetteNameHint => 'Cassette name';

  @override
  String get deleteCassetteTitle => 'DELETE CASSETTE?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count memos',
      one: '1 memo',
    );
    return '\"$label\" and its $_temp0 will be deleted. This cannot be undone.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count memos',
      one: '1 memo',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'empty · press to open';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · naming itself…';
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
    return 'today $time';
  }

  @override
  String get yesterday => 'yesterday';

  @override
  String get deleteCassette => 'Delete cassette';

  @override
  String get blankTape => 'A blank tape.\nPress the red key to record.';

  @override
  String get emptyTape => 'EMPTY TAPE';

  @override
  String memoCounter(int n, int total) {
    return 'MEMO $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'RECORDING MEMO $n';
  }

  @override
  String get summaryPlaceholder =>
      'The cassette summary appears once memos are transcribed.';

  @override
  String get back15 => 'Back 15 seconds';

  @override
  String get forward15 => 'Forward 15 seconds';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get recordNewMemo => 'Record a new memo';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get micPermissionNeeded =>
      'Microphone permission is required to record.';

  @override
  String get deleteMemoTitle => 'DELETE MEMO?';

  @override
  String deleteMemoBody(int n) {
    return 'Memo $n will be removed and the tape closes the gap. This cannot be undone.';
  }

  @override
  String get timelineLabel => 'Tape timeline';

  @override
  String timelinePosition(String position, String total) {
    return '$position of $total';
  }

  @override
  String get noSpeech => '(no speech)';

  @override
  String get transcriptionFailedRetry =>
      'transcription failed — tap to retry (the audio still plays)';

  @override
  String get queuedForTranscription => 'queued for transcription…';

  @override
  String get waitingForModel =>
      'waiting for the transcription model — download it in Settings';

  @override
  String memoDivider(int n, String date) {
    return 'Memo $n — $date';
  }

  @override
  String get summarizing => 'summarizing…';

  @override
  String get summaryFailedRetry => 'summary failed — tap to retry';

  @override
  String get transcribing => 'transcribing…';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get groupLanguage => 'Language';

  @override
  String get transcriptionLanguage => 'Transcription language';

  @override
  String get autoDetectValue => 'Auto-detect — set from your first memo';

  @override
  String get autoDetectOption => 'Auto-detect (from first recording)';

  @override
  String get transcriptionLanguageTitle => 'TRANSCRIPTION LANGUAGE';

  @override
  String get groupPlayback => 'Playback';

  @override
  String get boundaryChime => 'Boundary chime';

  @override
  String get boundaryChimeDesc =>
      'A soft cue as the tape rolls into the next memo. Off = fully seamless.';

  @override
  String get groupIntelligence => 'On-device intelligence';

  @override
  String get transcriptionModel => 'Transcription model';

  @override
  String get summaryModel => 'Summary model';

  @override
  String get summariesRow => 'Summaries';

  @override
  String get summariesRowDesc =>
      'Memo gists & cassette overviews, generated locally';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — installed, tap to manage';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — downloading $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — not downloaded yet · tap to set up';
  }

  @override
  String get groupAppearance => 'Appearance';

  @override
  String get themeRow => 'Theme';

  @override
  String get themeTitle => 'THEME';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get groupYourData => 'Your data';

  @override
  String get backupExport => 'Backup & export';

  @override
  String get backupExportDesc =>
      'Take your cassettes with you — audio, transcripts and summaries';

  @override
  String get aboutPrivacy => 'About & privacy';

  @override
  String get aboutPrivacyDesc => 'Audio never leaves this device';

  @override
  String get aboutTitle => 'ABOUT & PRIVACY';

  @override
  String get aboutBody =>
      'Diktafon listens, writes and summarizes right here on your phone.\n\nRecordings, transcripts and summaries never leave the device. There is no account, no cloud and no analytics. The only way data leaves is a backup or export you start yourself.';

  @override
  String get modelPickerTranscriptionTitle => 'TRANSCRIPTION MODEL';

  @override
  String get modelPickerSummaryTitle => 'SUMMARY MODEL';

  @override
  String pickerInstalled(String size) {
    return 'installed · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'downloading $pct %';
  }

  @override
  String pickerDownload(String size) {
    return 'download · $size';
  }

  @override
  String needsRam(int gb) {
    return 'needs ≥ $gb GB RAM';
  }

  @override
  String storageNote(int mb) {
    return 'Runs on this device only. Storage used by models: $mb MB.';
  }

  @override
  String get deleteModelTooltip => 'Delete model file';

  @override
  String modelReadyTranscribe(String label) {
    return '$label is ready — transcribing waiting memos.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label is ready — summarizing waiting memos.';
  }

  @override
  String downloadFailed(String label) {
    return 'Download of $label failed — check your connection and try again.';
  }

  @override
  String get firstRunWelcome => 'Welcome to Diktafon';

  @override
  String get firstRunIntro =>
      'It listens, writes and summarizes right here on your phone. Recordings, transcripts and summaries **never leave this device**. There is no account and no cloud.';

  @override
  String get allowMicRow => 'Allow microphone';

  @override
  String get micTapToGrant => 'Tap to grant access';

  @override
  String get rowMicrophone => 'Microphone';

  @override
  String get accessGranted => 'Access granted';

  @override
  String get micDeniedRetry =>
      'Not granted — tap to ask again, or allow the microphone in the system settings';

  @override
  String get rowTranscription => 'Transcription';

  @override
  String get rowSummaries => 'Summaries';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · ready';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · downloading — $pct %';
  }

  @override
  String get provisionWaiting => 'waiting to download…';

  @override
  String get provisionFailedRetry => 'download failed — tap to retry';

  @override
  String get downloadsFinishInBackground =>
      'Downloads finish in the background.';

  @override
  String get startRecordingKey => 'START RECORDING';

  @override
  String get backupTitle => 'BACKUP & EXPORT';

  @override
  String get backupIntro =>
      'Your device\'s own backup covers the cassette list, transcripts and summaries automatically. Audio recordings are large — take them with you explicitly: an export writes a folder with the audio files, the transcript and the summaries. Nothing is uploaded by Diktafon.';

  @override
  String get groupExport => 'Export';

  @override
  String get exportAll => 'Export all cassettes';

  @override
  String get exportAllDesc => 'Everything, into one folder you pick';

  @override
  String get exporting => 'Exporting…';

  @override
  String exportedTo(String path) {
    return 'Exported to $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Exported $count cassettes to $path.',
      one: 'Exported 1 cassette to $path.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get pickLocalFolder =>
      'That folder can\'t be written to directly — pick a local folder.';

  @override
  String exportNote(String date) {
    return 'Exported from Diktafon on $date.';
  }

  @override
  String get exportSummaryHeading => 'Summary';

  @override
  String get exportNotTranscribed => '(not transcribed)';
}
