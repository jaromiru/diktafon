// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get untitledCassette => 'Касета без назви';

  @override
  String get rename => 'Перейменувати';

  @override
  String get delete => 'Видалити';

  @override
  String get cancel => 'СКАСУВАТИ';

  @override
  String get save => 'ЗБЕРЕГТИ';

  @override
  String get deleteAction => 'ВИДАЛИТИ';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Назад';

  @override
  String get settingsTooltip => 'Налаштування';

  @override
  String get homeEmpty =>
      'Касет поки немає.\nНатисніть +, щоб почати нову плівку.';

  @override
  String get newCassette => 'Нова касета';

  @override
  String get renameCassetteTitle => 'ПЕРЕЙМЕНУВАТИ КАСЕТУ';

  @override
  String get cassetteNameHint => 'Назва касети';

  @override
  String get deleteCassetteTitle => 'ВИДАЛИТИ КАСЕТУ?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count запису',
      many: '$count записів',
      few: '$count записи',
      one: '$count запис',
    );
    return '«$label» та $_temp0 буде видалено. Цю дію не можна скасувати.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count запису',
      many: '$count записів',
      few: '$count записи',
      one: '$count запис',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'порожньо · натисніть, щоб відкрити';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · добирає назву…';
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
    return 'сьогодні $time';
  }

  @override
  String get yesterday => 'вчора';

  @override
  String get deleteCassette => 'Видалити касету';

  @override
  String get blankTape =>
      'Чиста плівка.\nНатисніть червону клавішу, щоб записати.';

  @override
  String get emptyTape => 'ПОРОЖНЯ ПЛІВКА';

  @override
  String memoCounter(int n, int total) {
    return 'ЗАПИС $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'ІДЕ ЗАПИС $n';
  }

  @override
  String get summaryPlaceholder =>
      'Підсумок касети з\'явиться, коли записи буде розшифровано.';

  @override
  String get back15 => 'Назад на 15 секунд';

  @override
  String get forward15 => 'Вперед на 15 секунд';

  @override
  String get play => 'Відтворити';

  @override
  String get pause => 'Пауза';

  @override
  String get recordNewMemo => 'Почати новий запис';

  @override
  String get stopRecording => 'Зупинити запис';

  @override
  String get micPermissionNeeded => 'Для запису потрібен доступ до мікрофона.';

  @override
  String get recordingFailed =>
      'Не вдалося почати запис — можливо, мікрофон зайнятий.';

  @override
  String get playbackError =>
      'Не вдалося відтворити запис — аудіофайл відсутній або пошкоджений.';

  @override
  String missingAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'На цьому пристрої відсутнє аудіо $count запису.',
      many: 'На цьому пристрої відсутнє аудіо $count записів.',
      few: 'На цьому пристрої відсутнє аудіо $count записів.',
      one: 'На цьому пристрої відсутнє аудіо $count запису.',
    );
    return '$_temp0';
  }

  @override
  String get deleteMemoTitle => 'ВИДАЛИТИ ЗАПИС?';

  @override
  String deleteMemoBody(int n) {
    return 'Запис $n буде видалено, і плівка зімкнеться без розриву. Цю дію не можна скасувати.';
  }

  @override
  String get timelineLabel => 'Шкала плівки';

  @override
  String timelinePosition(String position, String total) {
    return '$position з $total';
  }

  @override
  String get noSpeech => '(немає мовлення)';

  @override
  String get transcriptionFailedRetry =>
      'розшифровка не вдалася — натисніть, щоб повторити (звук і далі відтворюється)';

  @override
  String get queuedForTranscription => 'у черзі на розшифровку…';

  @override
  String get waitingForModel =>
      'очікування моделі розшифровки — завантажте її в налаштуваннях';

  @override
  String memoDivider(int n, String date) {
    return 'Запис $n — $date';
  }

  @override
  String get summarizing => 'складається підсумок…';

  @override
  String get summaryFailedRetry =>
      'не вдалося скласти підсумок — натисніть, щоб повторити';

  @override
  String get transcribing => 'іде розшифровка…';

  @override
  String get settingsTitle => 'НАЛАШТУВАННЯ';

  @override
  String get groupLanguage => 'Мова';

  @override
  String get transcriptionLanguage => 'Мова розшифровки';

  @override
  String get autoDetectValue =>
      'Автовизначення — кожен запис зберігає свою мову';

  @override
  String get autoDetectOption => 'Автовизначення (для кожного запису)';

  @override
  String get transcriptionLanguageTitle => 'МОВА РОЗШИФРОВКИ';

  @override
  String get groupPlayback => 'Відтворення';

  @override
  String get boundaryChime => 'Сигнал між записами';

  @override
  String get boundaryChimeDesc =>
      'М\'який звук, коли плівка переходить до наступного запису. Вимк. = повністю без швів.';

  @override
  String get groupIntelligence => 'Інтелект на пристрої';

  @override
  String get transcriptionModel => 'Модель розшифровки';

  @override
  String get summaryModel => 'Модель підсумків';

  @override
  String get summariesOffOption => 'Без підсумків';

  @override
  String get summariesOffDesc =>
      'Записи лише розшифровуються — без підсумків, оглядів касет і пропонованих назв.';

  @override
  String get whisperSmallDesc =>
      'Рекомендовано — найкращий баланс розміру та якості.';

  @override
  String get whisperSmallDescCapable =>
      'Легша й швидша — менш точна, особливо на шумних записах.';

  @override
  String get whisperLargeDesc =>
      'Вища точність; потрібен потужний пристрій (~2,5 ГБ ОЗП під час розшифровки).';

  @override
  String get whisperLargeDescCapable =>
      'Рекомендовано — помітно точніша, особливо в шумі (~2,5 ГБ ОЗП під час розшифровки).';

  @override
  String get llmDefaultDesc =>
      'Рекомендовано — компактні багатомовні підсумки.';

  @override
  String get llm4bDesc =>
      'Якісніші підсумки й назви; потрібен потужний пристрій (~3 ГБ ОЗП під час складання підсумків).';

  @override
  String get summariesOffValue => 'Без підсумків · натисніть, щоб налаштувати';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — установлено, натисніть для керування';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — завантажується $pct %';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — завантаження призупинено на $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — ще не завантажено · натисніть, щоб налаштувати';
  }

  @override
  String get groupAppearance => 'Оформлення';

  @override
  String get themeRow => 'Тема';

  @override
  String get themeTitle => 'ТЕМА';

  @override
  String get themeSystem => 'Як у системі';

  @override
  String get themeLight => 'Світла';

  @override
  String get themeDark => 'Темна';

  @override
  String get groupYourData => 'Ваші дані';

  @override
  String get backupExport => 'Експорт та імпорт';

  @override
  String get backupExportDesc =>
      'Заберіть касети із собою — звук, розшифровки й підсумки — або поверніть їх назад';

  @override
  String get aboutPrivacy => 'Про застосунок і приватність';

  @override
  String get aboutPrivacyDesc => 'Звук ніколи не покидає цей пристрій';

  @override
  String get aboutTitle => 'ПРО ЗАСТОСУНОК І ПРИВАТНІСТЬ';

  @override
  String get aboutBody =>
      'Диктафон слухає, записує й підсумовує просто у вашому телефоні.\n\nЗаписи, розшифровки та підсумки ніколи не покидають пристрій. Немає ні акаунта, ні хмари, ні аналітики. Дані покидають пристрій лише через резервну копію або експорт, які ви запускаєте самі.';

  @override
  String get aboutOpenSource =>
      'Диктафон — безкоштовний застосунок із відкритим вихідним кодом:';

  @override
  String get aboutPrivacyPolicy => 'Політика конфіденційності';

  @override
  String get modelPickerTranscriptionTitle => 'МОДЕЛЬ РОЗШИФРОВКИ';

  @override
  String get modelPickerSummaryTitle => 'МОДЕЛЬ ПІДСУМКІВ';

  @override
  String pickerInstalled(String size) {
    return 'установлено · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'завантажується $pct % — натисніть для паузи';
  }

  @override
  String pickerPaused(int pct) {
    return 'пауза на $pct % — натисніть, щоб продовжити';
  }

  @override
  String pickerDownload(String size) {
    return 'завантажити · $size';
  }

  @override
  String needsRam(int gb) {
    return 'потрібно ≥ $gb ГБ ОЗП';
  }

  @override
  String storageNote(int mb) {
    return 'Працює лише на цьому пристрої. Моделі займають: $mb МБ.';
  }

  @override
  String get deleteModelTooltip => 'Видалити файл моделі';

  @override
  String modelReadyTranscribe(String label) {
    return '$label готова — розшифровую записи, що очікують.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label готова — складаю підсумки записів, що очікують.';
  }

  @override
  String downloadFailed(String label) {
    return 'Не вдалося завантажити $label — перевірте з\'єднання та спробуйте ще раз.';
  }

  @override
  String get firstRunWelcome => 'Ласкаво просимо до Диктафона';

  @override
  String get firstRunIntro =>
      'Він слухає, записує й підсумовує просто у вашому телефоні. Записи, розшифровки та підсумки **ніколи не покидають цей пристрій**. Ні акаунта, ні хмари.';

  @override
  String get firstRunSetupHeader => 'Початкове налаштування';

  @override
  String get allowMicRow => 'Дозволити мікрофон';

  @override
  String get micTapToGrant => 'Натисніть, щоб надати доступ';

  @override
  String get rowMicrophone => 'Мікрофон';

  @override
  String get accessGranted => 'Доступ надано';

  @override
  String get micDeniedRetry =>
      'Не надано — натисніть, щоб запитати знову, або дозвольте мікрофон у системних налаштуваннях';

  @override
  String get rowTranscription => 'Розшифровка';

  @override
  String get rowSummaries => 'Підсумки';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · готово';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · завантажується — $pct %';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · пауза — $pct %';
  }

  @override
  String get provisionChoose =>
      'натисніть, щоб вибрати модель для завантаження';

  @override
  String get downloadsFinishInBackground => 'Завантаження завершиться у фоні.';

  @override
  String get startRecordingKey => 'ПОЧАТИ ЗАПИС';

  @override
  String get backupTitle => 'ЕКСПОРТ ТА ІМПОРТ';

  @override
  String get backupIntro =>
      'Резервна копія вашого пристрою сама охоплює список касет, розшифровки та підсумки. Аудіозаписи великі — заберіть їх явно: експорт запаковує звук, розшифровки й підсумки касети в один архів .zip, а імпорт архіву повертає їх назад. Диктафон нічого нікуди не надсилає.';

  @override
  String get groupExport => 'Експорт';

  @override
  String get exportAll => 'Експортувати всі касети';

  @override
  String get exportAllDesc => 'Усе в один архів';

  @override
  String get exporting => 'Експортую…';

  @override
  String exportedTo(String path) {
    return 'Експортовано до $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Експортовано $count касети до $path.',
      many: 'Експортовано $count касет до $path.',
      few: 'Експортовано $count касети до $path.',
      one: 'Експортовано $count касету до $path.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'Експорт не вдався: $error';
  }

  @override
  String get groupImport => 'Імпорт';

  @override
  String get importArchive => 'Імпортувати архів';

  @override
  String get importArchiveDesc => 'Додасть касети з попереднього експорту';

  @override
  String get importing => 'Імпортую…';

  @override
  String get importDialogTitle => 'ІМПОРТУВАТИ КАСЕТИ?';

  @override
  String get importDialogBody =>
      'Касети з архіву додадуться поряд із наявними — нічого не видаляється й не перезаписується. Імпорт касети, яка вже є, створить другу копію; її можна видалити вручну. Записи без розшифровки чи підсумку буде оброблено після імпорту.';

  @override
  String get importAction => 'ІМПОРТУВАТИ';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos запису',
      many: '$memos записів',
      few: '$memos записи',
      one: '$memos запис',
    );
    String _temp1 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos запису',
      many: '$memos записів',
      few: '$memos записи',
      one: '$memos запис',
    );
    String _temp2 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos запису',
      many: '$memos записів',
      few: '$memos записи',
      one: '$memos запис',
    );
    String _temp3 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos запису',
      many: '$memos записів',
      few: '$memos записи',
      one: '$memos запис',
    );
    String _temp4 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: 'Імпортовано $cassettes касети та $_temp0.',
      many: 'Імпортовано $cassettes касет та $_temp1.',
      few: 'Імпортовано $cassettes касети та $_temp2.',
      one: 'Імпортовано $cassettes касету та $_temp3.',
    );
    return '$_temp4';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Не вдалося імпортувати $count касети.',
      many: 'Не вдалося імпортувати $count касет.',
      few: 'Не вдалося імпортувати $count касети.',
      one: 'Не вдалося імпортувати $count касету.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound => 'У цьому архіві немає касет.';

  @override
  String importFailed(String error) {
    return 'Імпорт не вдався: $error';
  }

  @override
  String exportNote(String date) {
    return 'Експортовано з Диктафона $date.';
  }

  @override
  String get exportSummaryHeading => 'Підсумок';

  @override
  String get exportNotTranscribed => '(не розшифровано)';

  @override
  String get openSystemSettings => 'НАЛАШТУВАННЯ';

  @override
  String get changeColor => 'Змінити колір';

  @override
  String get retranscribe => 'Розшифрувати заново';

  @override
  String get retranscribeTitle => 'РОЗШИФРУВАТИ КАСЕТУ ЗАНОВО?';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count запису буде розшифровано заново',
      many: '$count записів буде розшифровано заново',
      few: '$count записи буде розшифровано заново',
      one: '$count запис буде розшифровано заново',
    );
    return '$_temp0 поточними моделями, і підсумок буде складено заново. Наявні розшифровки та підсумки буде замінено. Це може тривати певний час.';
  }

  @override
  String get retranscribeAction => 'РОЗШИФРУВАТИ';

  @override
  String get colorPickerTitle => 'КОЛІР КАСЕТИ';

  @override
  String colorSwatch(int n) {
    return 'Колір $n';
  }

  @override
  String get copyTranscript => 'Копіювати розшифровку';

  @override
  String get transcriptCopied => 'Розшифровку скопійовано.';

  @override
  String get deleteMemo => 'Видалити запис';

  @override
  String get memoActions => 'Дії із записом';

  @override
  String notifDownloading(String label) {
    return 'Завантажується $label';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label — установлено';
  }

  @override
  String get notifRecording => 'Триває запис';

  @override
  String get notifRecordingChannel => 'Запис';
}
