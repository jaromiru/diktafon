// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get untitledCassette => 'کاست بی‌نام';

  @override
  String get rename => 'تغییر نام';

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'لغو';

  @override
  String get save => 'ذخیره';

  @override
  String get deleteAction => 'حذف';

  @override
  String get ok => 'تأیید';

  @override
  String get back => 'بازگشت';

  @override
  String get settingsTooltip => 'تنظیمات';

  @override
  String get homeEmpty =>
      'هنوز کاستی ندارید.\nبرای شروع یک نوار تازه، + را بزنید.';

  @override
  String get newCassette => 'کاست جدید';

  @override
  String get renameCassetteTitle => 'تغییر نام کاست';

  @override
  String get cassetteNameHint => 'نام کاست';

  @override
  String get deleteCassetteTitle => 'کاست حذف شود؟';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count یادداشت',
      one: '$count یادداشت',
    );
    return '«$label» و $_temp0 آن حذف می‌شوند. این کار برگشت‌پذیر نیست.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count یادداشت',
      one: '$count یادداشت',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'خالی · برای باز کردن بزنید';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · در حال نام‌گذاری…';
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
    return 'امروز $time';
  }

  @override
  String get yesterday => 'دیروز';

  @override
  String get deleteCassette => 'حذف کاست';

  @override
  String get blankTape => 'یک نوار خالی.\nبرای ضبط، کلید قرمز را فشار دهید.';

  @override
  String get emptyTape => 'نوار خالی';

  @override
  String memoCounter(int n, int total) {
    return 'یادداشت $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'در حال ضبط یادداشت $n';
  }

  @override
  String get summaryPlaceholder =>
      'خلاصهٔ کاست پس از رونویسی یادداشت‌ها اینجا ظاهر می‌شود.';

  @override
  String get back15 => '۱۵ ثانیه به عقب';

  @override
  String get forward15 => '۱۵ ثانیه به جلو';

  @override
  String get play => 'پخش';

  @override
  String get pause => 'مکث';

  @override
  String get recordNewMemo => 'ضبط یادداشت جدید';

  @override
  String get stopRecording => 'توقف ضبط';

  @override
  String get micPermissionNeeded =>
      'برای ضبط، اجازهٔ دسترسی به میکروفون لازم است.';

  @override
  String get recordingFailed =>
      'ضبط شروع نشد — ممکن است میکروفون در حال استفاده باشد.';

  @override
  String get playbackError =>
      'پخش ناموفق بود — ممکن است فایل صوتی موجود نباشد یا آسیب دیده باشد.';

  @override
  String missingAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فایل صوتی $count یادداشت روی این دستگاه یافت نشد.',
      one: 'فایل صوتی یکی از یادداشت‌ها روی این دستگاه یافت نشد.',
    );
    return '$_temp0';
  }

  @override
  String get deleteMemoTitle => 'یادداشت حذف شود؟';

  @override
  String deleteMemoBody(int n) {
    return 'یادداشت $n حذف می‌شود و نوار جای خالی آن را پر می‌کند. این کار برگشت‌پذیر نیست.';
  }

  @override
  String get timelineLabel => 'خط زمانی نوار';

  @override
  String timelinePosition(String position, String total) {
    return '$position از $total';
  }

  @override
  String get noSpeech => '(بدون گفتار)';

  @override
  String get transcriptionFailedRetry =>
      'رونویسی ناموفق بود — برای تلاش دوباره لمس کنید (صدا همچنان قابل پخش است)';

  @override
  String get queuedForTranscription => 'در صف رونویسی…';

  @override
  String get waitingForModel =>
      'در انتظار مدل رونویسی — آن را از تنظیمات دانلود کنید';

  @override
  String memoDivider(int n, String date) {
    return 'یادداشت $n — $date';
  }

  @override
  String get summarizing => 'در حال خلاصه‌سازی…';

  @override
  String get summaryFailedRetry =>
      'خلاصه‌سازی ناموفق بود — برای تلاش دوباره لمس کنید';

  @override
  String get transcribing => 'در حال رونویسی…';

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get groupLanguage => 'زبان';

  @override
  String get transcriptionLanguage => 'زبان رونویسی';

  @override
  String get autoDetectValue =>
      'تشخیص خودکار — هر یادداشت زبان خودش را نگه می‌دارد';

  @override
  String get autoDetectOption => 'تشخیص خودکار (برای هر یادداشت)';

  @override
  String get transcriptionLanguageTitle => 'زبان رونویسی';

  @override
  String get groupPlayback => 'پخش';

  @override
  String get boundaryChime => 'صدای گذر';

  @override
  String get boundaryChimeDesc =>
      'نشانه‌ای ملایم هنگام رسیدن نوار به یادداشت بعدی. خاموش = کاملاً یکپارچه.';

  @override
  String get groupIntelligence => 'هوش روی دستگاه';

  @override
  String get transcriptionModel => 'مدل رونویسی';

  @override
  String get summaryModel => 'مدل خلاصه‌سازی';

  @override
  String get summariesOffOption => 'بدون خلاصه';

  @override
  String get summariesOffDesc =>
      'یادداشت‌ها فقط رونویسی می‌شوند — بدون چکیده، مرور کلی یا عنوان پیشنهادی.';

  @override
  String get whisperSmallDesc => 'پیشنهادی — بهترین تعادل بین حجم و کیفیت.';

  @override
  String get whisperSmallDescCapable =>
      'سبک‌تر و سریع‌تر — کم‌دقت‌تر، به‌ویژه در ضبط‌های پرنویز.';

  @override
  String get whisperLargeDesc =>
      'دقت بالاتر؛ به دستگاهی توانمند نیاز دارد (حدود ۲٫۵ گیگابایت رم هنگام رونویسی).';

  @override
  String get whisperLargeDescCapable =>
      'پیشنهادی — بسیار دقیق‌تر، به‌ویژه در محیط پرنویز (حدود ۲٫۵ گیگابایت رم هنگام رونویسی).';

  @override
  String get llmDefaultDesc => 'پیشنهادی — خلاصه‌های فشردهٔ چندزبانه.';

  @override
  String get llm4bDesc =>
      'خلاصه‌ها و عنوان‌های باکیفیت‌تر؛ به دستگاهی توانمند نیاز دارد (حدود ۳ گیگابایت رم هنگام خلاصه‌سازی).';

  @override
  String get summariesOffValue => 'بدون خلاصه · برای راه‌اندازی لمس کنید';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — نصب‌شده، برای مدیریت لمس کنید';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — در حال دانلود $pct٪';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — دانلود در $pct٪ متوقف شده';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — هنوز دانلود نشده · برای راه‌اندازی لمس کنید';
  }

  @override
  String get groupAppearance => 'ظاهر';

  @override
  String get themeRow => 'پوسته';

  @override
  String get themeTitle => 'پوسته';

  @override
  String get themeSystem => 'سیستم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تیره';

  @override
  String get groupYourData => 'داده‌های شما';

  @override
  String get backupExport => 'برون‌بری و درون‌ریزی';

  @override
  String get backupExportDesc =>
      'کاست‌هایتان را با خود ببرید — صدا، رونوشت‌ها و خلاصه‌ها — یا آن‌ها را بازگردانید';

  @override
  String get aboutPrivacy => 'درباره و حریم خصوصی';

  @override
  String get aboutPrivacyDesc => 'صدا هرگز از این دستگاه خارج نمی‌شود';

  @override
  String get aboutTitle => 'درباره و حریم خصوصی';

  @override
  String get aboutBody =>
      'Diktafon همین‌جا روی گوشی شما گوش می‌دهد، می‌نویسد و خلاصه می‌کند.\n\nضبط‌ها، رونوشت‌ها و خلاصه‌ها هرگز از دستگاه خارج نمی‌شوند. حساب کاربری، فضای ابری و ابزار تحلیلی در کار نیست. داده‌ها تنها زمانی از دستگاه خارج می‌شوند که خودتان پشتیبان‌گیری یا برون‌بری را آغاز کنید.';

  @override
  String get aboutOpenSource => 'Diktafon رایگان و متن‌باز است:';

  @override
  String get aboutPrivacyPolicy => 'سیاست حریم خصوصی';

  @override
  String get modelPickerTranscriptionTitle => 'مدل رونویسی';

  @override
  String get modelPickerSummaryTitle => 'مدل خلاصه‌سازی';

  @override
  String pickerInstalled(String size) {
    return 'نصب‌شده · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'در حال دانلود $pct٪ — برای مکث لمس کنید';
  }

  @override
  String pickerPaused(int pct) {
    return 'متوقف در $pct٪ — برای ادامه لمس کنید';
  }

  @override
  String pickerDownload(String size) {
    return 'دانلود · $size';
  }

  @override
  String needsRam(int gb) {
    return 'به دست‌کم $gb گیگابایت رم نیاز دارد';
  }

  @override
  String storageNote(int mb) {
    return 'فقط روی همین دستگاه اجرا می‌شود. فضای مصرفی مدل‌ها: $mb مگابایت.';
  }

  @override
  String get deleteModelTooltip => 'حذف فایل مدل';

  @override
  String modelReadyTranscribe(String label) {
    return '$label آماده است — یادداشت‌های در انتظار رونویسی می‌شوند.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label آماده است — یادداشت‌های در انتظار خلاصه می‌شوند.';
  }

  @override
  String downloadFailed(String label) {
    return 'دانلود $label ناموفق بود — اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';
  }

  @override
  String get firstRunWelcome => 'به Diktafon خوش آمدید';

  @override
  String get firstRunIntro =>
      'همین‌جا روی گوشی شما گوش می‌دهد، می‌نویسد و خلاصه می‌کند. ضبط‌ها، رونوشت‌ها و خلاصه‌ها **هرگز از این دستگاه خارج نمی‌شوند**. نه حساب کاربری در کار است و نه فضای ابری.';

  @override
  String get firstRunSetupHeader => 'راه‌اندازی اولیه';

  @override
  String get allowMicRow => 'اجازهٔ میکروفون';

  @override
  String get micTapToGrant => 'برای دادن دسترسی لمس کنید';

  @override
  String get rowMicrophone => 'میکروفون';

  @override
  String get accessGranted => 'دسترسی داده شد';

  @override
  String get micDeniedRetry =>
      'دسترسی داده نشد — برای درخواست دوباره لمس کنید، یا میکروفون را در تنظیمات سیستم مجاز کنید';

  @override
  String get rowTranscription => 'رونویسی';

  @override
  String get rowSummaries => 'خلاصه‌ها';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · آماده';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · در حال دانلود — $pct٪';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · متوقف — $pct٪';
  }

  @override
  String get provisionChoose => 'برای انتخاب و دانلود مدل لمس کنید';

  @override
  String get downloadsFinishInBackground =>
      'دانلودها در پس‌زمینه کامل می‌شوند.';

  @override
  String get startRecordingKey => 'شروع ضبط';

  @override
  String get backupTitle => 'برون‌بری و درون‌ریزی';

  @override
  String get backupIntro =>
      'پشتیبان‌گیری خود دستگاه، فهرست کاست‌ها، رونوشت‌ها و خلاصه‌ها را به‌طور خودکار پوشش می‌دهد. فایل‌های صوتی حجیم‌اند — آن‌ها را خودتان با خود ببرید: برون‌بری، صدا، رونوشت‌ها و خلاصه‌های یک کاست را در یک فایل .zip بسته‌بندی می‌کند و درون‌ریزی آن فایل همه را بازمی‌گرداند. Diktafon هیچ چیزی را آپلود نمی‌کند.';

  @override
  String get groupExport => 'برون‌بری';

  @override
  String get exportAll => 'برون‌بری همهٔ کاست‌ها';

  @override
  String get exportAllDesc => 'همه‌چیز، در یک فایل آرشیو';

  @override
  String get exporting => 'در حال برون‌بری…';

  @override
  String exportedTo(String path) {
    return 'در $path ذخیره شد.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کاست در $path ذخیره شد.',
      one: '$count کاست در $path ذخیره شد.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'برون‌بری ناموفق بود: $error';
  }

  @override
  String get groupImport => 'درون‌ریزی';

  @override
  String get importArchive => 'درون‌ریزی آرشیو';

  @override
  String get importArchiveDesc => 'افزودن کاست‌ها از یک برون‌بری قبلی';

  @override
  String get importing => 'در حال درون‌ریزی…';

  @override
  String get importDialogTitle => 'کاست‌ها درون‌ریزی شوند؟';

  @override
  String get importDialogBody =>
      'کاست‌های داخل آرشیو در کنار کاست‌های موجود اضافه می‌شوند — چیزی حذف یا تغییر داده نمی‌شود. درون‌ریزی کاستی که همین‌جا هست یک نسخهٔ دوم می‌سازد که می‌توانید خودتان آن را حذف کنید. یادداشت‌های بدون رونوشت یا خلاصه پس از درون‌ریزی پردازش می‌شوند.';

  @override
  String get importAction => 'درون‌ریزی';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos یادداشت',
      one: '$memos یادداشت',
    );
    String _temp1 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos یادداشت',
      one: '$memos یادداشت',
    );
    String _temp2 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: '$cassettes کاست با $_temp0 درون‌ریزی شد.',
      one: '$cassettes کاست با $_temp1 درون‌ریزی شد.',
    );
    return '$_temp2';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کاست درون‌ریزی نشد.',
      one: 'یک کاست درون‌ریزی نشد.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound => 'در آن آرشیو کاستی پیدا نشد.';

  @override
  String importFailed(String error) {
    return 'درون‌ریزی ناموفق بود: $error';
  }

  @override
  String exportNote(String date) {
    return 'در تاریخ $date از Diktafon برون‌بری شد.';
  }

  @override
  String get exportSummaryHeading => 'خلاصه';

  @override
  String get exportNotTranscribed => '(رونویسی‌نشده)';

  @override
  String get openSystemSettings => 'تنظیمات';

  @override
  String get changeColor => 'تغییر رنگ';

  @override
  String get retranscribe => 'رونویسی دوباره';

  @override
  String get retranscribeTitle => 'کاست دوباره رونویسی شود؟';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'همهٔ $count یادداشت با مدل‌های فعلی دوباره رونویسی می‌شوند',
      one: 'این یادداشت با مدل‌های فعلی دوباره رونویسی می‌شود',
    );
    return '$_temp0 و خلاصهٔ کاست از نو ساخته می‌شود. رونوشت‌ها و خلاصه‌های موجود جایگزین می‌شوند. این کار ممکن است کمی طول بکشد.';
  }

  @override
  String get retranscribeAction => 'رونویسی دوباره';

  @override
  String get colorPickerTitle => 'رنگ کاست';

  @override
  String colorSwatch(int n) {
    return 'رنگ $n';
  }

  @override
  String get copyTranscript => 'کپی رونوشت';

  @override
  String get transcriptCopied => 'رونوشت کپی شد.';

  @override
  String get deleteMemo => 'حذف یادداشت';

  @override
  String get memoActions => 'گزینه‌های یادداشت';

  @override
  String notifDownloading(String label) {
    return 'در حال دانلود $label';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label نصب شد';
  }

  @override
  String get notifRecording => 'در حال ضبط';

  @override
  String get notifRecordingChannel => 'ضبط';
}
