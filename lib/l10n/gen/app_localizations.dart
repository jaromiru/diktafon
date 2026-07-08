import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pl'),
    Locale('pt'),
  ];

  /// No description provided for @untitledCassette.
  ///
  /// In en, this message translates to:
  /// **'Untitled cassette'**
  String get untitledCassette;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get save;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAction;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @homeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cassettes yet.\nPress + to start a new tape.'**
  String get homeEmpty;

  /// No description provided for @newCassette.
  ///
  /// In en, this message translates to:
  /// **'New cassette'**
  String get newCassette;

  /// No description provided for @renameCassetteTitle.
  ///
  /// In en, this message translates to:
  /// **'RENAME CASSETTE'**
  String get renameCassetteTitle;

  /// No description provided for @cassetteNameHint.
  ///
  /// In en, this message translates to:
  /// **'Cassette name'**
  String get cassetteNameHint;

  /// No description provided for @deleteCassetteTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE CASSETTE?'**
  String get deleteCassetteTitle;

  /// No description provided for @deleteCassetteBody.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" and its {count, plural, =1{1 memo} other{{count} memos}} will be deleted. This cannot be undone.'**
  String deleteCassetteBody(String label, int count);

  /// Memo count on a cassette card / export row
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 memo} other{{count} memos}}'**
  String memoCount(int count);

  /// No description provided for @cardEmptyMeta.
  ///
  /// In en, this message translates to:
  /// **'empty · press to open'**
  String get cardEmptyMeta;

  /// No description provided for @cardMetaNaming.
  ///
  /// In en, this message translates to:
  /// **'{memos} · naming itself…'**
  String cardMetaNaming(String memos);

  /// No description provided for @cardMetaUpdated.
  ///
  /// In en, this message translates to:
  /// **'{memos} · {date}'**
  String cardMetaUpdated(String memos, String date);

  /// No description provided for @cardSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}, {memos}'**
  String cardSemantics(String label, String memos);

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String todayAt(String time);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @deleteCassette.
  ///
  /// In en, this message translates to:
  /// **'Delete cassette'**
  String get deleteCassette;

  /// No description provided for @blankTape.
  ///
  /// In en, this message translates to:
  /// **'A blank tape.\nPress the red key to record.'**
  String get blankTape;

  /// No description provided for @emptyTape.
  ///
  /// In en, this message translates to:
  /// **'EMPTY TAPE'**
  String get emptyTape;

  /// LCD counter row, kept in caps like a tape deck
  ///
  /// In en, this message translates to:
  /// **'MEMO {n} / {total}'**
  String memoCounter(int n, int total);

  /// No description provided for @recordingMemo.
  ///
  /// In en, this message translates to:
  /// **'RECORDING MEMO {n}'**
  String recordingMemo(int n);

  /// No description provided for @summaryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'The cassette summary appears once memos are transcribed.'**
  String get summaryPlaceholder;

  /// No description provided for @back15.
  ///
  /// In en, this message translates to:
  /// **'Back 15 seconds'**
  String get back15;

  /// No description provided for @forward15.
  ///
  /// In en, this message translates to:
  /// **'Forward 15 seconds'**
  String get forward15;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @recordNewMemo.
  ///
  /// In en, this message translates to:
  /// **'Record a new memo'**
  String get recordNewMemo;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// No description provided for @micPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record.'**
  String get micPermissionNeeded;

  /// No description provided for @deleteMemoTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE MEMO?'**
  String get deleteMemoTitle;

  /// No description provided for @deleteMemoBody.
  ///
  /// In en, this message translates to:
  /// **'Memo {n} will be removed and the tape closes the gap. This cannot be undone.'**
  String deleteMemoBody(int n);

  /// No description provided for @timelineLabel.
  ///
  /// In en, this message translates to:
  /// **'Tape timeline'**
  String get timelineLabel;

  /// No description provided for @timelinePosition.
  ///
  /// In en, this message translates to:
  /// **'{position} of {total}'**
  String timelinePosition(String position, String total);

  /// No description provided for @noSpeech.
  ///
  /// In en, this message translates to:
  /// **'(no speech)'**
  String get noSpeech;

  /// No description provided for @transcriptionFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'transcription failed — tap to retry (the audio still plays)'**
  String get transcriptionFailedRetry;

  /// No description provided for @queuedForTranscription.
  ///
  /// In en, this message translates to:
  /// **'queued for transcription…'**
  String get queuedForTranscription;

  /// No description provided for @waitingForModel.
  ///
  /// In en, this message translates to:
  /// **'waiting for the transcription model — download it in Settings'**
  String get waitingForModel;

  /// No description provided for @memoDivider.
  ///
  /// In en, this message translates to:
  /// **'Memo {n} — {date}'**
  String memoDivider(int n, String date);

  /// No description provided for @summarizing.
  ///
  /// In en, this message translates to:
  /// **'summarizing…'**
  String get summarizing;

  /// No description provided for @summaryFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'summary failed — tap to retry'**
  String get summaryFailedRetry;

  /// No description provided for @transcribing.
  ///
  /// In en, this message translates to:
  /// **'transcribing…'**
  String get transcribing;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @groupLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get groupLanguage;

  /// No description provided for @transcriptionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Transcription language'**
  String get transcriptionLanguage;

  /// No description provided for @autoDetectValue.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect — each memo keeps its own language'**
  String get autoDetectValue;

  /// No description provided for @autoDetectOption.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect (per memo)'**
  String get autoDetectOption;

  /// No description provided for @transcriptionLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'TRANSCRIPTION LANGUAGE'**
  String get transcriptionLanguageTitle;

  /// No description provided for @groupPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get groupPlayback;

  /// No description provided for @boundaryChime.
  ///
  /// In en, this message translates to:
  /// **'Boundary chime'**
  String get boundaryChime;

  /// No description provided for @boundaryChimeDesc.
  ///
  /// In en, this message translates to:
  /// **'A soft cue as the tape rolls into the next memo. Off = fully seamless.'**
  String get boundaryChimeDesc;

  /// No description provided for @groupIntelligence.
  ///
  /// In en, this message translates to:
  /// **'On-device intelligence'**
  String get groupIntelligence;

  /// No description provided for @transcriptionModel.
  ///
  /// In en, this message translates to:
  /// **'Transcription model'**
  String get transcriptionModel;

  /// No description provided for @summaryModel.
  ///
  /// In en, this message translates to:
  /// **'Summary model'**
  String get summaryModel;

  /// No description provided for @summariesRow.
  ///
  /// In en, this message translates to:
  /// **'Summaries'**
  String get summariesRow;

  /// No description provided for @summariesRowDesc.
  ///
  /// In en, this message translates to:
  /// **'Memo gists & cassette overviews, generated locally'**
  String get summariesRowDesc;

  /// No description provided for @modelInstalled.
  ///
  /// In en, this message translates to:
  /// **'{label} · {size} — installed, tap to manage'**
  String modelInstalled(String label, String size);

  /// No description provided for @modelDownloading.
  ///
  /// In en, this message translates to:
  /// **'{label} — downloading {pct} %'**
  String modelDownloading(String label, int pct);

  /// No description provided for @modelNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{label} — not downloaded yet · tap to set up'**
  String modelNotDownloaded(String label);

  /// No description provided for @groupAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get groupAppearance;

  /// No description provided for @themeRow.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeRow;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'THEME'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @groupYourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get groupYourData;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get backupExport;

  /// No description provided for @backupExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Take your cassettes with you — audio, transcripts and summaries'**
  String get backupExportDesc;

  /// No description provided for @aboutPrivacy.
  ///
  /// In en, this message translates to:
  /// **'About & privacy'**
  String get aboutPrivacy;

  /// No description provided for @aboutPrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Audio never leaves this device'**
  String get aboutPrivacyDesc;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'ABOUT & PRIVACY'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Diktafon listens, writes and summarizes right here on your phone.\n\nRecordings, transcripts and summaries never leave the device. There is no account, no cloud and no analytics. The only way data leaves is a backup or export you start yourself.'**
  String get aboutBody;

  /// No description provided for @modelPickerTranscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'TRANSCRIPTION MODEL'**
  String get modelPickerTranscriptionTitle;

  /// No description provided for @modelPickerSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'SUMMARY MODEL'**
  String get modelPickerSummaryTitle;

  /// No description provided for @pickerInstalled.
  ///
  /// In en, this message translates to:
  /// **'installed · {size}'**
  String pickerInstalled(String size);

  /// No description provided for @pickerDownloading.
  ///
  /// In en, this message translates to:
  /// **'downloading {pct} %'**
  String pickerDownloading(int pct);

  /// No description provided for @pickerDownload.
  ///
  /// In en, this message translates to:
  /// **'download · {size}'**
  String pickerDownload(String size);

  /// No description provided for @needsRam.
  ///
  /// In en, this message translates to:
  /// **'needs ≥ {gb} GB RAM'**
  String needsRam(int gb);

  /// No description provided for @storageNote.
  ///
  /// In en, this message translates to:
  /// **'Runs on this device only. Storage used by models: {mb} MB.'**
  String storageNote(int mb);

  /// No description provided for @deleteModelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete model file'**
  String get deleteModelTooltip;

  /// No description provided for @modelReadyTranscribe.
  ///
  /// In en, this message translates to:
  /// **'{label} is ready — transcribing waiting memos.'**
  String modelReadyTranscribe(String label);

  /// No description provided for @modelReadySummarize.
  ///
  /// In en, this message translates to:
  /// **'{label} is ready — summarizing waiting memos.'**
  String modelReadySummarize(String label);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download of {label} failed — check your connection and try again.'**
  String downloadFailed(String label);

  /// No description provided for @firstRunWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Diktafon'**
  String get firstRunWelcome;

  /// The **…** span is rendered bold; keep exactly one such span.
  ///
  /// In en, this message translates to:
  /// **'It listens, writes and summarizes right here on your phone. Recordings, transcripts and summaries **never leave this device**. There is no account and no cloud.'**
  String get firstRunIntro;

  /// No description provided for @firstRunSetupHeader.
  ///
  /// In en, this message translates to:
  /// **'First-time setup'**
  String get firstRunSetupHeader;

  /// No description provided for @allowMicRow.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone'**
  String get allowMicRow;

  /// No description provided for @micTapToGrant.
  ///
  /// In en, this message translates to:
  /// **'Tap to grant access'**
  String get micTapToGrant;

  /// No description provided for @rowMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get rowMicrophone;

  /// No description provided for @accessGranted.
  ///
  /// In en, this message translates to:
  /// **'Access granted'**
  String get accessGranted;

  /// No description provided for @micDeniedRetry.
  ///
  /// In en, this message translates to:
  /// **'Not granted — tap to ask again, or allow the microphone in the system settings'**
  String get micDeniedRetry;

  /// No description provided for @rowTranscription.
  ///
  /// In en, this message translates to:
  /// **'Transcription'**
  String get rowTranscription;

  /// No description provided for @rowSummaries.
  ///
  /// In en, this message translates to:
  /// **'Summaries'**
  String get rowSummaries;

  /// No description provided for @provisionReady.
  ///
  /// In en, this message translates to:
  /// **'{label} · {size} · ready'**
  String provisionReady(String label, String size);

  /// No description provided for @provisionDownloading.
  ///
  /// In en, this message translates to:
  /// **'{label} · {size} · downloading — {pct} %'**
  String provisionDownloading(String label, String size, int pct);

  /// No description provided for @provisionChoose.
  ///
  /// In en, this message translates to:
  /// **'tap to choose a model to download'**
  String get provisionChoose;

  /// No description provided for @downloadsFinishInBackground.
  ///
  /// In en, this message translates to:
  /// **'Downloads finish in the background.'**
  String get downloadsFinishInBackground;

  /// No description provided for @startRecordingKey.
  ///
  /// In en, this message translates to:
  /// **'START RECORDING'**
  String get startRecordingKey;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'EXPORT DATA'**
  String get backupTitle;

  /// No description provided for @backupIntro.
  ///
  /// In en, this message translates to:
  /// **'Your device\'s own backup covers the cassette list, transcripts and summaries automatically. Audio recordings are large — take them with you explicitly: an export writes a folder with the audio files, the transcript and the summaries. Nothing is uploaded by Diktafon.'**
  String get backupIntro;

  /// No description provided for @groupExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get groupExport;

  /// No description provided for @exportAll.
  ///
  /// In en, this message translates to:
  /// **'Export all cassettes'**
  String get exportAll;

  /// No description provided for @exportAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Everything, into one folder you pick'**
  String get exportAllDesc;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get exporting;

  /// No description provided for @exportedTo.
  ///
  /// In en, this message translates to:
  /// **'Exported to {path}.'**
  String exportedTo(String path);

  /// No description provided for @exportedAllTo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Exported 1 cassette to {path}.} other{Exported {count} cassettes to {path}.}}'**
  String exportedAllTo(int count, String path);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @pickLocalFolder.
  ///
  /// In en, this message translates to:
  /// **'That folder can\'t be written to directly — pick a local folder.'**
  String get pickLocalFolder;

  /// No description provided for @exportNote.
  ///
  /// In en, this message translates to:
  /// **'Exported from Diktafon on {date}.'**
  String exportNote(String date);

  /// No description provided for @exportSummaryHeading.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get exportSummaryHeading;

  /// No description provided for @exportNotTranscribed.
  ///
  /// In en, this message translates to:
  /// **'(not transcribed)'**
  String get exportNotTranscribed;

  /// No description provided for @openSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get openSystemSettings;

  /// No description provided for @changeColor.
  ///
  /// In en, this message translates to:
  /// **'Change color'**
  String get changeColor;

  /// No description provided for @colorPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'CASSETTE COLOR'**
  String get colorPickerTitle;

  /// No description provided for @colorSwatch.
  ///
  /// In en, this message translates to:
  /// **'Color {n}'**
  String colorSwatch(int n);

  /// No description provided for @copyTranscript.
  ///
  /// In en, this message translates to:
  /// **'Copy transcription'**
  String get copyTranscript;

  /// No description provided for @transcriptCopied.
  ///
  /// In en, this message translates to:
  /// **'Transcription copied.'**
  String get transcriptCopied;

  /// No description provided for @deleteMemo.
  ///
  /// In en, this message translates to:
  /// **'Delete memo'**
  String get deleteMemo;

  /// No description provided for @memoActions.
  ///
  /// In en, this message translates to:
  /// **'Memo actions'**
  String get memoActions;

  /// No description provided for @cleanupRow.
  ///
  /// In en, this message translates to:
  /// **'Transcript cleanup'**
  String get cleanupRow;

  /// No description provided for @cleanupRowDesc.
  ///
  /// In en, this message translates to:
  /// **'The summary model tidies fresh transcripts — spelling & recognition slips'**
  String get cleanupRowDesc;

  /// No description provided for @notifDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {label}'**
  String notifDownloading(String label);

  /// No description provided for @notifModelInstalled.
  ///
  /// In en, this message translates to:
  /// **'{label} installed'**
  String notifModelInstalled(String label);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'cs',
    'de',
    'en',
    'es',
    'fr',
    'pl',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
