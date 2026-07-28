// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get untitledCassette => 'बिना नाम की कैसेट';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get delete => 'हटाएं';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get deleteAction => 'हटाएं';

  @override
  String get ok => 'ठीक है';

  @override
  String get back => 'वापस';

  @override
  String get settingsTooltip => 'सेटिंग्स';

  @override
  String get homeEmpty =>
      'अभी कोई कैसेट नहीं है।\nनया टेप शुरू करने के लिए + दबाएं।';

  @override
  String get newCassette => 'नई कैसेट';

  @override
  String get renameCassetteTitle => 'कैसेट का नाम बदलें';

  @override
  String get cassetteNameHint => 'कैसेट का नाम';

  @override
  String get deleteCassetteTitle => 'कैसेट हटाएं?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'उसके $count मेमो',
      one: 'उसका $count मेमो',
    );
    return '\"$label\" और $_temp0 हटा दिए जाएंगे। इसे पूर्ववत नहीं किया जा सकता।';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मेमो',
      one: '$count मेमो',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'खाली · खोलने के लिए दबाएं';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · खुद नाम रख रही है…';
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
    return 'आज $time';
  }

  @override
  String get yesterday => 'कल';

  @override
  String get deleteCassette => 'कैसेट हटाएं';

  @override
  String get blankTape => 'टेप खाली है।\nरिकॉर्ड करने के लिए लाल बटन दबाएं।';

  @override
  String get emptyTape => 'खाली टेप';

  @override
  String memoCounter(int n, int total) {
    return 'मेमो $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'मेमो $n रिकॉर्ड हो रहा है';
  }

  @override
  String get summaryPlaceholder =>
      'मेमो ट्रांसक्राइब होने पर कैसेट का सारांश यहां दिखेगा।';

  @override
  String get back15 => '15 सेकंड पीछे';

  @override
  String get forward15 => '15 सेकंड आगे';

  @override
  String get play => 'चलाएं';

  @override
  String get pause => 'रोकें';

  @override
  String get recordNewMemo => 'नया मेमो रिकॉर्ड करें';

  @override
  String get stopRecording => 'रिकॉर्डिंग बंद करें';

  @override
  String get micPermissionNeeded =>
      'रिकॉर्ड करने के लिए माइक्रोफ़ोन की अनुमति ज़रूरी है।';

  @override
  String get recordingFailed =>
      'रिकॉर्डिंग शुरू नहीं हो सकी — शायद माइक्रोफ़ोन पहले से इस्तेमाल में है।';

  @override
  String get playbackError =>
      'प्लेबैक नहीं हो सका — ऑडियो फ़ाइल शायद गायब या खराब है।';

  @override
  String missingAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'इस डिवाइस पर $count मेमो के ऑडियो मौजूद नहीं हैं।',
      one: 'इस डिवाइस पर $count मेमो का ऑडियो मौजूद नहीं है।',
    );
    return '$_temp0';
  }

  @override
  String get deleteMemoTitle => 'मेमो हटाएं?';

  @override
  String deleteMemoBody(int n) {
    return 'मेमो $n हटा दिया जाएगा और टेप की खाली जगह अपने-आप भर जाएगी। इसे पूर्ववत नहीं किया जा सकता।';
  }

  @override
  String get timelineLabel => 'टेप की टाइमलाइन';

  @override
  String timelinePosition(String position, String total) {
    return '$total में से $position';
  }

  @override
  String get noSpeech => '(कुछ बोला नहीं गया)';

  @override
  String get transcriptionFailedRetry =>
      'ट्रांसक्रिप्शन विफल — दोबारा कोशिश के लिए टैप करें (ऑडियो अब भी चलता है)';

  @override
  String get queuedForTranscription => 'ट्रांसक्रिप्शन की कतार में…';

  @override
  String get waitingForModel =>
      'ट्रांसक्रिप्शन मॉडल का इंतज़ार है — उसे सेटिंग्स में डाउनलोड करें';

  @override
  String memoDivider(int n, String date) {
    return 'मेमो $n — $date';
  }

  @override
  String get summarizing => 'सारांश बन रहा है…';

  @override
  String get summaryFailedRetry => 'सारांश विफल — दोबारा कोशिश के लिए टैप करें';

  @override
  String get transcribing => 'ट्रांसक्राइब हो रहा है…';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get groupLanguage => 'भाषा';

  @override
  String get transcriptionLanguage => 'ट्रांसक्रिप्शन की भाषा';

  @override
  String get autoDetectValue =>
      'अपने-आप पहचान — हर मेमो अपनी ही भाषा में रहता है';

  @override
  String get autoDetectOption => 'अपने-आप पहचान (हर मेमो के लिए)';

  @override
  String get transcriptionLanguageTitle => 'ट्रांसक्रिप्शन की भाषा';

  @override
  String get groupPlayback => 'प्लेबैक';

  @override
  String get boundaryChime => 'मेमो बदलने की धुन';

  @override
  String get boundaryChimeDesc =>
      'टेप के अगले मेमो में जाते ही एक हल्की-सी धुन। बंद रखने पर टेप बिल्कुल बिना रुकावट चलता है।';

  @override
  String get groupIntelligence => 'डिवाइस पर इंटेलिजेंस';

  @override
  String get transcriptionModel => 'ट्रांसक्रिप्शन मॉडल';

  @override
  String get summaryModel => 'सारांश मॉडल';

  @override
  String get summariesOffOption => 'सारांश नहीं';

  @override
  String get summariesOffDesc =>
      'मेमो सिर्फ़ ट्रांसक्राइब ही होंगे — न सार, न कैसेट-सारांश, न सुझाए गए नाम।';

  @override
  String get whisperSmallDesc =>
      'सुझाया गया — साइज़ और क्वालिटी का सबसे अच्छा संतुलन।';

  @override
  String get whisperSmallDescCapable =>
      'हल्का और तेज़ — कम सटीक, खासकर शोर वाली रिकॉर्डिंग में।';

  @override
  String get whisperLargeDesc =>
      'ज़्यादा सटीक; सक्षम डिवाइस चाहिए (ट्रांसक्राइब करते समय ~2.5 GB RAM)।';

  @override
  String get whisperLargeDescCapable =>
      'सुझाया गया — काफ़ी ज़्यादा सटीक, खासकर शोर में (ट्रांसक्राइब करते समय ~2.5 GB RAM)।';

  @override
  String get llmDefaultDesc => 'सुझाया गया — छोटे, बहुभाषी सारांश।';

  @override
  String get llm4bDesc =>
      'बेहतर सारांश और नाम; सक्षम डिवाइस चाहिए (सारांश बनाते समय ~3 GB RAM)।';

  @override
  String get summariesOffValue => 'सारांश नहीं · सेटअप के लिए टैप करें';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — इंस्टॉल है, मैनेज करने के लिए टैप करें';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — $pct % डाउनलोड हुआ';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — डाउनलोड $pct % पर रुका है';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — अभी डाउनलोड नहीं हुआ · सेटअप के लिए टैप करें';
  }

  @override
  String get groupAppearance => 'दिखावट';

  @override
  String get themeRow => 'थीम';

  @override
  String get themeTitle => 'थीम';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get groupYourData => 'आपका डेटा';

  @override
  String get backupExport => 'निर्यात और आयात';

  @override
  String get backupExportDesc =>
      'अपनी कैसेट साथ ले जाएं — ऑडियो, ट्रांसक्रिप्ट और सारांश — या उन्हें वापस लाएं';

  @override
  String get aboutPrivacy => 'ऐप की जानकारी और निजता';

  @override
  String get aboutPrivacyDesc => 'ऑडियो कभी इस डिवाइस से बाहर नहीं जाता';

  @override
  String get aboutTitle => 'ऐप की जानकारी और निजता';

  @override
  String get aboutBody =>
      'Diktafon आपके फ़ोन पर ही सुनता, लिखता और सारांश बनाता है।\n\nरिकॉर्डिंग, ट्रांसक्रिप्ट और सारांश कभी डिवाइस से बाहर नहीं जाते। न कोई खाता है, न क्लाउड, न कोई एनालिटिक्स। डेटा सिर्फ़ तभी बाहर जाता है जब आप खुद बैकअप या निर्यात करते हैं।';

  @override
  String get aboutOpenSource => 'Diktafon मुफ़्त और ओपन सोर्स है:';

  @override
  String get aboutPrivacyPolicy => 'निजता नीति';

  @override
  String get modelPickerTranscriptionTitle => 'ट्रांसक्रिप्शन मॉडल';

  @override
  String get modelPickerSummaryTitle => 'सारांश मॉडल';

  @override
  String pickerInstalled(String size) {
    return 'इंस्टॉल है · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return '$pct % डाउनलोड हुआ — रोकने के लिए टैप करें';
  }

  @override
  String pickerPaused(int pct) {
    return '$pct % पर रुका — जारी रखने के लिए टैप करें';
  }

  @override
  String pickerDownload(String size) {
    return 'डाउनलोड करें · $size';
  }

  @override
  String needsRam(int gb) {
    return '≥ $gb GB RAM चाहिए';
  }

  @override
  String storageNote(int mb) {
    return 'सिर्फ़ इसी डिवाइस पर चलता है। मॉडल $mb MB स्टोरेज ले रहे हैं।';
  }

  @override
  String get deleteModelTooltip => 'मॉडल फ़ाइल हटाएं';

  @override
  String modelReadyTranscribe(String label) {
    return '$label तैयार है — रुके हुए मेमो ट्रांसक्राइब हो रहे हैं।';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label तैयार है — रुके हुए मेमो के सारांश बन रहे हैं।';
  }

  @override
  String downloadFailed(String label) {
    return '$label का डाउनलोड विफल हुआ — कनेक्शन जांचें और दोबारा कोशिश करें।';
  }

  @override
  String get firstRunWelcome => 'Diktafon में आपका स्वागत है';

  @override
  String get firstRunIntro =>
      'यह आपके फ़ोन पर ही सुनता, लिखता और सारांश बनाता है। रिकॉर्डिंग, ट्रांसक्रिप्ट और सारांश **कभी इस डिवाइस से बाहर नहीं जाते**। न कोई खाता, न कोई क्लाउड।';

  @override
  String get firstRunSetupHeader => 'पहली बार का सेटअप';

  @override
  String get allowMicRow => 'माइक्रोफ़ोन की अनुमति दें';

  @override
  String get micTapToGrant => 'अनुमति देने के लिए टैप करें';

  @override
  String get rowMicrophone => 'माइक्रोफ़ोन';

  @override
  String get accessGranted => 'अनुमति मिल गई';

  @override
  String get micDeniedRetry =>
      'अनुमति नहीं मिली — दोबारा पूछने के लिए टैप करें, या सिस्टम सेटिंग्स में माइक्रोफ़ोन की अनुमति दें';

  @override
  String get rowTranscription => 'ट्रांसक्रिप्शन';

  @override
  String get rowSummaries => 'सारांश';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · तैयार';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · डाउनलोड हो रहा है — $pct %';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · रुका हुआ — $pct %';
  }

  @override
  String get provisionChoose => 'मॉडल चुनकर डाउनलोड करने के लिए टैप करें';

  @override
  String get downloadsFinishInBackground =>
      'डाउनलोड बैकग्राउंड में पूरे हो जाते हैं।';

  @override
  String get startRecordingKey => 'रिकॉर्डिंग शुरू करें';

  @override
  String get backupTitle => 'निर्यात और आयात';

  @override
  String get backupIntro =>
      'आपके डिवाइस का अपना बैकअप कैसेट सूची, ट्रांसक्रिप्ट और सारांश अपने-आप सहेज लेता है। ऑडियो रिकॉर्डिंग बड़ी होती हैं — उन्हें खुद साथ ले जाएं: निर्यात एक कैसेट का ऑडियो, ट्रांसक्रिप्ट और सारांश एक .zip आर्काइव में समेट देता है, और आर्काइव का आयात उन्हें वापस ले आता है। Diktafon कुछ भी अपलोड नहीं करता।';

  @override
  String get groupExport => 'निर्यात';

  @override
  String get exportAll => 'सभी कैसेट निर्यात करें';

  @override
  String get exportAllDesc => 'सब कुछ, एक ही आर्काइव फ़ाइल में';

  @override
  String get exporting => 'निर्यात हो रहा है…';

  @override
  String exportedTo(String path) {
    return '$path में निर्यात किया गया।';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कैसेट $path में निर्यात की गईं।',
      one: '$count कैसेट $path में निर्यात की गई।',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'निर्यात विफल: $error';
  }

  @override
  String get groupImport => 'आयात';

  @override
  String get importArchive => 'आर्काइव आयात करें';

  @override
  String get importArchiveDesc => 'पहले किए गए निर्यात से कैसेट जोड़ें';

  @override
  String get importing => 'आयात हो रहा है…';

  @override
  String get importDialogTitle => 'कैसेट आयात करें?';

  @override
  String get importDialogBody =>
      'आर्काइव की कैसेट आपकी मौजूदा कैसेट के साथ जुड़ जाती हैं — कुछ भी हटाया या बदला नहीं जाता। पहले से मौजूद कैसेट को आयात करने पर उसकी दूसरी प्रति बन जाती है, जिसे आप खुद हटा सकते हैं। जिन मेमो की ट्रांसक्रिप्ट या सारांश नहीं है, वे आयात के बाद प्रोसेस किए जाते हैं।';

  @override
  String get importAction => 'आयात करें';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos मेमो हैं',
      one: '$memos मेमो है',
    );
    String _temp1 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos मेमो हैं',
      one: '$memos मेमो है',
    );
    String _temp2 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: '$cassettes कैसेट आयात की गईं, जिनमें $_temp0।',
      one: '$cassettes कैसेट आयात की गई, जिसमें $_temp1।',
    );
    return '$_temp2';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कैसेट आयात नहीं हो सकीं।',
      one: '$count कैसेट आयात नहीं हो सकी।',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound => 'उस आर्काइव में कोई कैसेट नहीं मिली।';

  @override
  String importFailed(String error) {
    return 'आयात विफल: $error';
  }

  @override
  String exportNote(String date) {
    return 'Diktafon से $date को निर्यात किया गया।';
  }

  @override
  String get exportSummaryHeading => 'सारांश';

  @override
  String get exportNotTranscribed => '(ट्रांसक्राइब नहीं हुआ)';

  @override
  String get openSystemSettings => 'सेटिंग्स';

  @override
  String get changeColor => 'रंग बदलें';

  @override
  String get retranscribe => 'दोबारा ट्रांसक्राइब करें';

  @override
  String get retranscribeTitle => 'कैसेट दोबारा ट्रांसक्राइब करें?';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'सभी $count मेमो मौजूदा मॉडलों से दोबारा ट्रांसक्राइब होंगे',
      one: '$count मेमो मौजूदा मॉडलों से दोबारा ट्रांसक्राइब होगा',
    );
    return '$_temp0 और सारांश नए सिरे से बनाया जाएगा। मौजूदा ट्रांसक्रिप्ट और सारांश बदल दिए जाएंगे। इसमें कुछ समय लग सकता है।';
  }

  @override
  String get retranscribeAction => 'दोबारा ट्रांसक्राइब करें';

  @override
  String get colorPickerTitle => 'कैसेट का रंग';

  @override
  String colorSwatch(int n) {
    return 'रंग $n';
  }

  @override
  String get copyTranscript => 'ट्रांसक्रिप्ट कॉपी करें';

  @override
  String get transcriptCopied => 'ट्रांसक्रिप्ट कॉपी हो गई।';

  @override
  String get deleteMemo => 'मेमो हटाएं';

  @override
  String get memoActions => 'मेमो के विकल्प';

  @override
  String notifDownloading(String label) {
    return '$label डाउनलोड हो रहा है';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label इंस्टॉल हो गया';
  }
}
