// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get untitledCassette => 'كاسيت بلا اسم';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get deleteAction => 'حذف';

  @override
  String get ok => 'حسنًا';

  @override
  String get back => 'رجوع';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get homeEmpty => 'لا توجد كاسيتات بعد.\nاضغط على + لبدء شريط جديد.';

  @override
  String get newCassette => 'كاسيت جديد';

  @override
  String get renameCassetteTitle => 'إعادة تسمية الكاسيت';

  @override
  String get cassetteNameHint => 'اسم الكاسيت';

  @override
  String get deleteCassetteTitle => 'حذف الكاسيت؟';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ومعه $count مذكرة',
      many: 'ومعه $count مذكرة',
      few: 'ومعه $count مذكرات',
      two: 'ومعه مذكرتان',
      one: 'ومعه مذكرة واحدة',
      zero: 'وهو لا يحتوي على أي مذكرات',
    );
    return 'سيُحذف الكاسيت «$label» $_temp0. لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مذكرة',
      many: '$count مذكرة',
      few: '$count مذكرات',
      two: 'مذكرتان',
      one: 'مذكرة واحدة',
      zero: 'لا مذكرات',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'فارغ · اضغط للفتح';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · جارٍ اختيار الاسم…';
  }

  @override
  String cardMetaUpdated(String memos, String date) {
    return '$memos · $date';
  }

  @override
  String cardSemantics(String label, String memos) {
    return '$label، $memos';
  }

  @override
  String todayAt(String time) {
    return 'اليوم $time';
  }

  @override
  String get yesterday => 'أمس';

  @override
  String get deleteCassette => 'حذف الكاسيت';

  @override
  String get blankTape => 'شريط فارغ.\nاضغط على الزر الأحمر للتسجيل.';

  @override
  String get emptyTape => 'شريط فارغ';

  @override
  String memoCounter(int n, int total) {
    return 'المذكرة $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'تسجيل المذكرة $n';
  }

  @override
  String get summaryPlaceholder => 'يظهر ملخص الكاسيت بعد تفريغ المذكرات.';

  @override
  String get back15 => 'رجوع 15 ثانية';

  @override
  String get forward15 => 'تقديم 15 ثانية';

  @override
  String get play => 'تشغيل';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get recordNewMemo => 'تسجيل مذكرة جديدة';

  @override
  String get stopRecording => 'إيقاف التسجيل';

  @override
  String get micPermissionNeeded => 'إذن الميكروفون مطلوب للتسجيل.';

  @override
  String get recordingFailed =>
      'تعذر بدء التسجيل — قد يكون الميكروفون قيد الاستخدام.';

  @override
  String get playbackError =>
      'فشل التشغيل — قد يكون ملف الصوت مفقودًا أو تالفًا.';

  @override
  String missingAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'صوت $count مذكرة مفقود على هذا الجهاز.',
      many: 'صوت $count مذكرة مفقود على هذا الجهاز.',
      few: 'صوت $count مذكرات مفقود على هذا الجهاز.',
      two: 'صوت مذكرتين مفقود على هذا الجهاز.',
      one: 'صوت مذكرة واحدة مفقود على هذا الجهاز.',
      zero: 'لا توجد ملفات صوت مفقودة على هذا الجهاز.',
    );
    return '$_temp0';
  }

  @override
  String get deleteMemoTitle => 'حذف المذكرة؟';

  @override
  String deleteMemoBody(int n) {
    return 'ستُزال المذكرة $n وسيُغلق الشريط الفجوة. لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get timelineLabel => 'الخط الزمني للشريط';

  @override
  String timelinePosition(String position, String total) {
    return '$position من $total';
  }

  @override
  String get noSpeech => '(لا كلام)';

  @override
  String get transcriptionFailedRetry =>
      'فشل التفريغ — انقر لإعادة المحاولة (لا يزال الصوت قابلًا للتشغيل)';

  @override
  String get queuedForTranscription => 'في قائمة انتظار التفريغ…';

  @override
  String get waitingForModel => 'في انتظار نموذج التفريغ — نزِّله من الإعدادات';

  @override
  String memoDivider(int n, String date) {
    return 'المذكرة $n — $date';
  }

  @override
  String get summarizing => 'جارٍ التلخيص…';

  @override
  String get summaryFailedRetry => 'فشل التلخيص — انقر لإعادة المحاولة';

  @override
  String get transcribing => 'جارٍ التفريغ…';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get groupLanguage => 'اللغة';

  @override
  String get transcriptionLanguage => 'لغة التفريغ';

  @override
  String get autoDetectValue => 'اكتشاف تلقائي — كل مذكرة تحتفظ بلغتها';

  @override
  String get autoDetectOption => 'اكتشاف تلقائي (لكل مذكرة)';

  @override
  String get transcriptionLanguageTitle => 'لغة التفريغ';

  @override
  String get groupPlayback => 'التشغيل';

  @override
  String get boundaryChime => 'نغمة الفاصل';

  @override
  String get boundaryChimeDesc =>
      'تنبيه خفيف عندما ينتقل الشريط إلى المذكرة التالية. إيقافها يجعل التشغيل متواصلًا تمامًا.';

  @override
  String get groupIntelligence => 'الذكاء على الجهاز';

  @override
  String get transcriptionModel => 'نموذج التفريغ';

  @override
  String get summaryModel => 'نموذج التلخيص';

  @override
  String get summariesOffOption => 'بدون ملخصات';

  @override
  String get summariesOffDesc =>
      'تُفرَّغ المذكرات نصيًا فقط — من دون خلاصات أو ملخصات عامة أو عناوين مقترحة.';

  @override
  String get whisperSmallDesc => 'موصى به — أفضل توازن بين الحجم والجودة.';

  @override
  String get whisperSmallDescCapable =>
      'أخف وأسرع — أقل دقة، خصوصًا في التسجيلات الصاخبة.';

  @override
  String get whisperLargeDesc =>
      'دقة أعلى؛ يحتاج إلى جهاز قوي (نحو 2.5 غيغابايت من الذاكرة أثناء التفريغ).';

  @override
  String get whisperLargeDescCapable =>
      'موصى به — أدق بكثير، خصوصًا مع الضوضاء (نحو 2.5 غيغابايت من الذاكرة أثناء التفريغ).';

  @override
  String get llmDefaultDesc => 'موصى به — ملخصات موجزة متعددة اللغات.';

  @override
  String get llm4bDesc =>
      'ملخصات وعناوين أعلى جودة؛ يحتاج إلى جهاز قوي (نحو 3 غيغابايت من الذاكرة أثناء التلخيص).';

  @override
  String get summariesOffValue => 'بدون ملخصات · انقر للإعداد';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — مثبَّت، انقر للإدارة';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — جارٍ التنزيل $pct %';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — التنزيل متوقف مؤقتًا عند $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — لم يُنزَّل بعد · انقر للإعداد';
  }

  @override
  String get groupAppearance => 'المظهر';

  @override
  String get themeRow => 'السمة';

  @override
  String get themeTitle => 'السمة';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتحة';

  @override
  String get themeDark => 'داكنة';

  @override
  String get groupYourData => 'بياناتك';

  @override
  String get backupExport => 'التصدير والاستيراد';

  @override
  String get backupExportDesc =>
      'خذ كاسيتاتك معك — الصوت والنصوص والملخصات — أو أعدها إلى الجهاز';

  @override
  String get aboutPrivacy => 'حول التطبيق والخصوصية';

  @override
  String get aboutPrivacyDesc => 'الصوت لا يغادر هذا الجهاز أبدًا';

  @override
  String get aboutTitle => 'حول التطبيق والخصوصية';

  @override
  String get aboutBody =>
      'Diktafon يستمع ويكتب ويلخّص هنا على هاتفك مباشرة.\n\nالتسجيلات والنصوص والملخصات لا تغادر الجهاز أبدًا. لا حساب ولا سحابة ولا تحليلات استخدام. الطريقة الوحيدة لخروج البيانات هي نسخة احتياطية أو تصدير تبدأه بنفسك.';

  @override
  String get aboutOpenSource => 'Diktafon مجاني ومفتوح المصدر:';

  @override
  String get aboutPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get modelPickerTranscriptionTitle => 'نموذج التفريغ';

  @override
  String get modelPickerSummaryTitle => 'نموذج التلخيص';

  @override
  String pickerInstalled(String size) {
    return 'مثبَّت · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'جارٍ التنزيل $pct % — انقر للإيقاف المؤقت';
  }

  @override
  String pickerPaused(int pct) {
    return 'متوقف مؤقتًا عند $pct % — انقر للاستئناف';
  }

  @override
  String pickerDownload(String size) {
    return 'تنزيل · $size';
  }

  @override
  String needsRam(int gb) {
    return 'يتطلب ذاكرة ≥ $gb غيغابايت';
  }

  @override
  String storageNote(int mb) {
    return 'يعمل على هذا الجهاز فقط. مساحة التخزين المستخدمة للنماذج: $mb ميغابايت.';
  }

  @override
  String get deleteModelTooltip => 'حذف ملف النموذج';

  @override
  String modelReadyTranscribe(String label) {
    return '$label جاهز — جارٍ تفريغ المذكرات المنتظرة.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label جاهز — جارٍ تلخيص المذكرات المنتظرة.';
  }

  @override
  String downloadFailed(String label) {
    return 'فشل تنزيل $label — تحقق من اتصالك وحاول مرة أخرى.';
  }

  @override
  String get firstRunWelcome => 'مرحبًا بك في Diktafon';

  @override
  String get firstRunIntro =>
      'يستمع ويكتب ويلخّص هنا على هاتفك مباشرة. التسجيلات والنصوص والملخصات **لا تغادر هذا الجهاز أبدًا**. لا حساب ولا سحابة.';

  @override
  String get firstRunSetupHeader => 'الإعداد الأولي';

  @override
  String get allowMicRow => 'السماح بالميكروفون';

  @override
  String get micTapToGrant => 'انقر لمنح الإذن';

  @override
  String get rowMicrophone => 'الميكروفون';

  @override
  String get accessGranted => 'تم منح الإذن';

  @override
  String get micDeniedRetry =>
      'لم يُمنح الإذن — انقر للطلب مجددًا، أو اسمح بالميكروفون من إعدادات النظام';

  @override
  String get rowTranscription => 'التفريغ';

  @override
  String get rowSummaries => 'الملخصات';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · جاهز';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · جارٍ التنزيل — $pct %';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · متوقف مؤقتًا — $pct %';
  }

  @override
  String get provisionChoose => 'انقر لاختيار نموذج لتنزيله';

  @override
  String get downloadsFinishInBackground => 'تكتمل التنزيلات في الخلفية.';

  @override
  String get startRecordingKey => 'بدء التسجيل';

  @override
  String get backupTitle => 'التصدير والاستيراد';

  @override
  String get backupIntro =>
      'يشمل النسخ الاحتياطي الخاص بجهازك قائمة الكاسيتات والنصوص والملخصات تلقائيًا. أما التسجيلات الصوتية فحجمها كبير — خذها معك بنفسك: يجمع التصدير صوت الكاسيت ونصوصه وملخصاته في أرشيف zip واحد، ويعيدها استيراد الأرشيف. لا يرفع Diktafon أي شيء.';

  @override
  String get groupExport => 'التصدير';

  @override
  String get exportAll => 'تصدير كل الكاسيتات';

  @override
  String get exportAllDesc => 'كل شيء، في ملف أرشيف واحد';

  @override
  String get exporting => 'جارٍ التصدير…';

  @override
  String exportedTo(String path) {
    return 'تم التصدير إلى $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تصدير $count كاسيت إلى $path.',
      many: 'تم تصدير $count كاسيتًا إلى $path.',
      few: 'تم تصدير $count كاسيتات إلى $path.',
      two: 'تم تصدير كاسيتين إلى $path.',
      one: 'تم تصدير كاسيت واحد إلى $path.',
      zero: 'لم يُصدَّر أي كاسيت إلى $path.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'فشل التصدير: $error';
  }

  @override
  String get groupImport => 'الاستيراد';

  @override
  String get importArchive => 'استيراد أرشيف';

  @override
  String get importArchiveDesc => 'أضف كاسيتات من تصدير سابق';

  @override
  String get importing => 'جارٍ الاستيراد…';

  @override
  String get importDialogTitle => 'استيراد الكاسيتات؟';

  @override
  String get importDialogBody =>
      'تُضاف الكاسيتات الموجودة في الأرشيف إلى جانب كاسيتاتك الحالية — لا يُحذف أو يتغير شيء. استيراد كاسيت موجود لديك بالفعل ينشئ نسخة ثانية يمكنك حذفها يدويًا. المذكرات التي ينقصها نص أو ملخص تُعالج بعد الاستيراد.';

  @override
  String get importAction => 'استيراد';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos مذكرة',
      many: '$memos مذكرة',
      few: '$memos مذكرات',
      two: 'مذكرتان',
      one: 'مذكرة واحدة',
      zero: 'بدون مذكرات',
    );
    String _temp1 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos مذكرة',
      many: '$memos مذكرة',
      few: '$memos مذكرات',
      two: 'مذكرتان',
      one: 'مذكرة واحدة',
      zero: 'بدون مذكرات',
    );
    String _temp2 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos مذكرة',
      many: '$memos مذكرة',
      few: '$memos مذكرات',
      two: 'مذكرتان',
      one: 'مذكرة واحدة',
      zero: 'بدون مذكرات',
    );
    String _temp3 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: 'تم استيراد $cassettes من الكاسيتات — $_temp0.',
      two: 'تم استيراد كاسيتين — $_temp1.',
      one: 'تم استيراد كاسيت واحد — $_temp2.',
    );
    return '$_temp3';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تعذر استيراد $count كاسيت.',
      many: 'تعذر استيراد $count كاسيتًا.',
      few: 'تعذر استيراد $count كاسيتات.',
      two: 'تعذر استيراد كاسيتين.',
      one: 'تعذر استيراد كاسيت واحد.',
      zero: 'لم يتعذر استيراد أي كاسيت.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound => 'لم يُعثر على كاسيتات في هذا الأرشيف.';

  @override
  String importFailed(String error) {
    return 'فشل الاستيراد: $error';
  }

  @override
  String exportNote(String date) {
    return 'صُدِّر من Diktafon في $date.';
  }

  @override
  String get exportSummaryHeading => 'الملخص';

  @override
  String get exportNotTranscribed => '(لم يُفرَّغ)';

  @override
  String get openSystemSettings => 'الإعدادات';

  @override
  String get changeColor => 'تغيير اللون';

  @override
  String get retranscribe => 'إعادة التفريغ';

  @override
  String get retranscribeTitle => 'إعادة تفريغ الكاسيت؟';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'جميع المذكرات الـ $count',
      many: 'جميع المذكرات الـ $count',
      few: 'جميع المذكرات الـ $count',
      two: 'المذكرتين',
      one: 'المذكرة',
      zero: 'المذكرات',
    );
    return 'سيُعاد تفريغ $_temp0 بالنماذج الحالية وسيُعاد إنشاء الملخص. ستحل النتائج الجديدة محل النصوص والملخصات الحالية. قد يستغرق هذا بعض الوقت.';
  }

  @override
  String get retranscribeAction => 'إعادة التفريغ';

  @override
  String get colorPickerTitle => 'لون الكاسيت';

  @override
  String colorSwatch(int n) {
    return 'اللون $n';
  }

  @override
  String get copyTranscript => 'نسخ النص';

  @override
  String get transcriptCopied => 'تم نسخ النص.';

  @override
  String get deleteMemo => 'حذف المذكرة';

  @override
  String get memoActions => 'إجراءات المذكرة';

  @override
  String notifDownloading(String label) {
    return 'جارٍ تنزيل $label';
  }

  @override
  String notifModelInstalled(String label) {
    return 'تم تثبيت $label';
  }

  @override
  String get notifRecording => 'جارٍ التسجيل';

  @override
  String get notifRecordingChannel => 'التسجيل';
}
