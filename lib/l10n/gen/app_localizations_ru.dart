// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get untitledCassette => 'Кассета без названия';

  @override
  String get rename => 'Переименовать';

  @override
  String get delete => 'Удалить';

  @override
  String get cancel => 'ОТМЕНА';

  @override
  String get save => 'СОХРАНИТЬ';

  @override
  String get deleteAction => 'УДАЛИТЬ';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Назад';

  @override
  String get settingsTooltip => 'Настройки';

  @override
  String get homeEmpty =>
      'Кассет пока нет.\nНажмите +, чтобы начать новую плёнку.';

  @override
  String get newCassette => 'Новая кассета';

  @override
  String get renameCassetteTitle => 'ПЕРЕИМЕНОВАТЬ КАССЕТУ';

  @override
  String get cassetteNameHint => 'Название кассеты';

  @override
  String get deleteCassetteTitle => 'УДАЛИТЬ КАССЕТУ?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записи',
      many: '$count записей',
      few: '$count записи',
      one: '$count запись',
    );
    return '«$label» и $_temp0 будут удалены. Это нельзя отменить.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записи',
      many: '$count записей',
      few: '$count записи',
      one: '$count запись',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'пусто · нажмите, чтобы открыть';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · подбирает название…';
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
    return 'сегодня $time';
  }

  @override
  String get yesterday => 'вчера';

  @override
  String get deleteCassette => 'Удалить кассету';

  @override
  String get blankTape =>
      'Чистая плёнка.\nНажмите красную клавишу, чтобы записать.';

  @override
  String get emptyTape => 'ПУСТАЯ ПЛЁНКА';

  @override
  String memoCounter(int n, int total) {
    return 'ЗАПИСЬ $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'ИДЁТ ЗАПИСЬ $n';
  }

  @override
  String get summaryPlaceholder =>
      'Сводка кассеты появится, когда записи будут расшифрованы.';

  @override
  String get back15 => 'Назад на 15 секунд';

  @override
  String get forward15 => 'Вперёд на 15 секунд';

  @override
  String get play => 'Воспроизвести';

  @override
  String get pause => 'Пауза';

  @override
  String get recordNewMemo => 'Начать новую запись';

  @override
  String get stopRecording => 'Остановить запись';

  @override
  String get micPermissionNeeded => 'Для записи нужен доступ к микрофону.';

  @override
  String get deleteMemoTitle => 'УДАЛИТЬ ЗАПИСЬ?';

  @override
  String deleteMemoBody(int n) {
    return 'Запись $n будет удалена, и плёнка сомкнётся без разрыва. Это нельзя отменить.';
  }

  @override
  String get timelineLabel => 'Шкала плёнки';

  @override
  String timelinePosition(String position, String total) {
    return '$position из $total';
  }

  @override
  String get noSpeech => '(нет речи)';

  @override
  String get transcriptionFailedRetry =>
      'расшифровка не удалась — нажмите, чтобы повторить (звук по-прежнему играет)';

  @override
  String get queuedForTranscription => 'в очереди на расшифровку…';

  @override
  String get waitingForModel =>
      'ожидание модели расшифровки — скачайте её в настройках';

  @override
  String memoDivider(int n, String date) {
    return 'Запись $n — $date';
  }

  @override
  String get summarizing => 'составляется сводка…';

  @override
  String get summaryFailedRetry =>
      'сводка не удалась — нажмите, чтобы повторить';

  @override
  String get transcribing => 'идёт расшифровка…';

  @override
  String get settingsTitle => 'НАСТРОЙКИ';

  @override
  String get groupLanguage => 'Язык';

  @override
  String get transcriptionLanguage => 'Язык расшифровки';

  @override
  String get autoDetectValue =>
      'Автоопределение — каждая запись хранит свой язык';

  @override
  String get autoDetectOption => 'Автоопределение (для каждой записи)';

  @override
  String get transcriptionLanguageTitle => 'ЯЗЫК РАСШИФРОВКИ';

  @override
  String get groupPlayback => 'Воспроизведение';

  @override
  String get boundaryChime => 'Сигнал между записями';

  @override
  String get boundaryChimeDesc =>
      'Мягкий звук, когда плёнка переходит к следующей записи. Выкл. = полностью без швов.';

  @override
  String get groupIntelligence => 'Интеллект на устройстве';

  @override
  String get transcriptionModel => 'Модель расшифровки';

  @override
  String get summaryModel => 'Модель сводок';

  @override
  String get summariesRow => 'Сводки';

  @override
  String get summariesRowDesc =>
      'Суть записей и обзоры кассет, создаются прямо на устройстве';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — установлено, нажмите для управления';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — скачивается $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — ещё не скачано · нажмите, чтобы настроить';
  }

  @override
  String get groupAppearance => 'Оформление';

  @override
  String get themeRow => 'Тема';

  @override
  String get themeTitle => 'ТЕМА';

  @override
  String get themeSystem => 'Как в системе';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get groupYourData => 'Ваши данные';

  @override
  String get backupExport => 'Экспорт данных';

  @override
  String get backupExportDesc =>
      'Заберите кассеты с собой — звук, расшифровки и сводки';

  @override
  String get aboutPrivacy => 'О приложении и приватность';

  @override
  String get aboutPrivacyDesc => 'Звук никогда не покидает это устройство';

  @override
  String get aboutTitle => 'О ПРИЛОЖЕНИИ И ПРИВАТНОСТЬ';

  @override
  String get aboutBody =>
      'Диктафон слушает, записывает и составляет сводки прямо в вашем телефоне.\n\nЗаписи, расшифровки и сводки никогда не покидают устройство. Нет ни аккаунта, ни облака, ни аналитики. Данные покидают устройство только через резервную копию или экспорт, которые запускаете вы сами.';

  @override
  String get aboutOpenSource =>
      'Диктафон — бесплатное приложение с открытым исходным кодом:';

  @override
  String get modelPickerTranscriptionTitle => 'МОДЕЛЬ РАСШИФРОВКИ';

  @override
  String get modelPickerSummaryTitle => 'МОДЕЛЬ СВОДОК';

  @override
  String pickerInstalled(String size) {
    return 'установлено · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'скачивается $pct %';
  }

  @override
  String pickerDownload(String size) {
    return 'скачать · $size';
  }

  @override
  String needsRam(int gb) {
    return 'нужно ≥ $gb ГБ ОЗУ';
  }

  @override
  String storageNote(int mb) {
    return 'Работает только на этом устройстве. Модели занимают: $mb МБ.';
  }

  @override
  String get deleteModelTooltip => 'Удалить файл модели';

  @override
  String modelReadyTranscribe(String label) {
    return '$label готова — расшифровываю ожидающие записи.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label готова — составляю сводки ожидающих записей.';
  }

  @override
  String downloadFailed(String label) {
    return 'Не удалось скачать $label — проверьте соединение и попробуйте ещё раз.';
  }

  @override
  String get firstRunWelcome => 'Добро пожаловать в Диктафон';

  @override
  String get firstRunIntro =>
      'Он слушает, записывает и составляет сводки прямо в вашем телефоне. Записи, расшифровки и сводки **никогда не покидают это устройство**. Ни аккаунта, ни облака.';

  @override
  String get firstRunSetupHeader => 'Первоначальная настройка';

  @override
  String get allowMicRow => 'Разрешить микрофон';

  @override
  String get micTapToGrant => 'Нажмите, чтобы дать доступ';

  @override
  String get rowMicrophone => 'Микрофон';

  @override
  String get accessGranted => 'Доступ разрешён';

  @override
  String get micDeniedRetry =>
      'Не разрешено — нажмите, чтобы спросить снова, или разрешите микрофон в настройках системы';

  @override
  String get rowTranscription => 'Расшифровка';

  @override
  String get rowSummaries => 'Сводки';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · готово';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · скачивается — $pct %';
  }

  @override
  String get provisionChoose => 'нажмите, чтобы выбрать модель для скачивания';

  @override
  String get downloadsFinishInBackground => 'Скачивание завершится в фоне.';

  @override
  String get startRecordingKey => 'НАЧАТЬ ЗАПИСЬ';

  @override
  String get backupTitle => 'ЭКСПОРТ ДАННЫХ';

  @override
  String get backupIntro =>
      'Резервная копия вашего устройства сама охватывает список кассет, расшифровки и сводки. Аудиозаписи большие — заберите их явно: экспорт создаёт папку со звуковыми файлами, расшифровкой и сводками. Диктафон ничего никуда не загружает.';

  @override
  String get groupExport => 'Экспорт';

  @override
  String get exportAll => 'Экспортировать все кассеты';

  @override
  String get exportAllDesc => 'Всё в одну папку на ваш выбор';

  @override
  String get exporting => 'Экспортирую…';

  @override
  String exportedTo(String path) {
    return 'Экспортировано в $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Экспортировано $count кассеты в $path.',
      many: 'Экспортировано $count кассет в $path.',
      few: 'Экспортированы $count кассеты в $path.',
      one: 'Экспортирована $count кассета в $path.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'Экспорт не удался: $error';
  }

  @override
  String get pickLocalFolder =>
      'В эту папку нельзя писать напрямую — выберите локальную папку.';

  @override
  String exportNote(String date) {
    return 'Экспортировано из Диктафона $date.';
  }

  @override
  String get exportSummaryHeading => 'Сводка';

  @override
  String get exportNotTranscribed => '(не расшифровано)';

  @override
  String get openSystemSettings => 'НАСТРОЙКИ';

  @override
  String get changeColor => 'Изменить цвет';

  @override
  String get retranscribe => 'Расшифровать заново';

  @override
  String get retranscribeTitle => 'РАСШИФРОВАТЬ КАССЕТУ ЗАНОВО?';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записи будут расшифрованы заново',
      many: '$count записей будут расшифрованы заново',
      few: '$count записи будут расшифрованы заново',
      one: '$count запись будет расшифрована заново',
    );
    return '$_temp0 текущими моделями, и сводка будет составлена заново. Существующие расшифровки и сводки будут заменены. Это может занять время.';
  }

  @override
  String get retranscribeAction => 'РАСШИФРОВАТЬ';

  @override
  String get colorPickerTitle => 'ЦВЕТ КАССЕТЫ';

  @override
  String colorSwatch(int n) {
    return 'Цвет $n';
  }

  @override
  String get copyTranscript => 'Копировать расшифровку';

  @override
  String get transcriptCopied => 'Расшифровка скопирована.';

  @override
  String get deleteMemo => 'Удалить запись';

  @override
  String get memoActions => 'Действия с записью';

  @override
  String get cleanupRow => 'Чистка расшифровок';

  @override
  String get cleanupRowDesc =>
      'Модель сводок приводит свежие расшифровки в порядок — орфография и ослышки';

  @override
  String notifDownloading(String label) {
    return 'Скачивается $label';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label — установлено';
  }
}
