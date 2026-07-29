// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get untitledCassette => '未命名卡带';

  @override
  String get rename => '重命名';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get deleteAction => '删除';

  @override
  String get ok => '确定';

  @override
  String get back => '返回';

  @override
  String get settingsTooltip => '设置';

  @override
  String get homeEmpty => '还没有卡带。\n按 + 开始一盘新磁带。';

  @override
  String get newCassette => '新卡带';

  @override
  String get renameCassetteTitle => '重命名卡带';

  @override
  String get cassetteNameHint => '卡带名称';

  @override
  String get deleteCassetteTitle => '删除卡带？';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条备忘',
    );
    return '“$label”和其中的 $_temp0将被删除。此操作无法撤销。';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条备忘',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => '空白 · 点按打开';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · 正在命名…';
  }

  @override
  String cardMetaUpdated(String memos, String date) {
    return '$memos · $date';
  }

  @override
  String cardSemantics(String label, String memos) {
    return '$label，$memos';
  }

  @override
  String todayAt(String time) {
    return '今天 $time';
  }

  @override
  String get yesterday => '昨天';

  @override
  String get deleteCassette => '删除卡带';

  @override
  String get blankTape => '一盘空白磁带。\n按下红色按键开始录音。';

  @override
  String get emptyTape => '空白磁带';

  @override
  String memoCounter(int n, int total) {
    return '备忘 $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return '正在录制备忘 $n';
  }

  @override
  String get summaryPlaceholder => '备忘转写完成后，这里会显示卡带摘要。';

  @override
  String get back15 => '快退 15 秒';

  @override
  String get forward15 => '快进 15 秒';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get recordNewMemo => '录制新备忘';

  @override
  String get stopRecording => '停止录音';

  @override
  String get micPermissionNeeded => '录音需要麦克风权限。';

  @override
  String get recordingFailed => '无法开始录音，麦克风可能正被占用。';

  @override
  String get playbackError => '播放失败，音频文件可能丢失或已损坏。';

  @override
  String missingAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此设备上缺少 $count 条备忘的音频。',
    );
    return '$_temp0';
  }

  @override
  String get deleteMemoTitle => '删除备忘？';

  @override
  String deleteMemoBody(int n) {
    return '备忘 $n 将被移除，磁带会自动衔接。此操作无法撤销。';
  }

  @override
  String get timelineLabel => '磁带时间轴';

  @override
  String timelinePosition(String position, String total) {
    return '$position，共 $total';
  }

  @override
  String get noSpeech => '（无语音）';

  @override
  String get transcriptionFailedRetry => '转写失败，点按重试（音频仍可播放）';

  @override
  String get queuedForTranscription => '排队等待转写…';

  @override
  String get waitingForModel => '等待转写模型，请在设置中下载';

  @override
  String memoDivider(int n, String date) {
    return '备忘 $n — $date';
  }

  @override
  String get summarizing => '正在生成摘要…';

  @override
  String get summaryFailedRetry => '摘要失败，点按重试';

  @override
  String get transcribing => '正在转写…';

  @override
  String get settingsTitle => '设置';

  @override
  String get groupLanguage => '语言';

  @override
  String get transcriptionLanguage => '转写语言';

  @override
  String get autoDetectValue => '自动检测，每条备忘保留自己的语言';

  @override
  String get autoDetectOption => '自动检测（按备忘）';

  @override
  String get transcriptionLanguageTitle => '转写语言';

  @override
  String get groupPlayback => '播放';

  @override
  String get boundaryChime => '切换提示音';

  @override
  String get boundaryChimeDesc => '磁带转入下一条备忘时的轻柔提示。关闭后完全无缝。';

  @override
  String get groupIntelligence => '设备端智能';

  @override
  String get transcriptionModel => '转写模型';

  @override
  String get summaryModel => '摘要模型';

  @override
  String get summariesOffOption => '无摘要';

  @override
  String get summariesOffDesc => '备忘只做转写，不生成要点、卡带概览或标题建议。';

  @override
  String get whisperSmallDesc => '推荐：体积与质量的最佳平衡。';

  @override
  String get whisperSmallDescCapable => '更轻更快，但准确度较低，嘈杂录音中尤其明显。';

  @override
  String get whisperLargeDesc => '准确度更高；需要性能较强的设备（转写时约占用 2.5 GB 内存）。';

  @override
  String get whisperLargeDescCapable =>
      '推荐：准确度高得多，嘈杂环境中尤其明显（转写时约占用 2.5 GB 内存）。';

  @override
  String get llmDefaultDesc => '推荐：精简的多语言摘要。';

  @override
  String get llm4bDesc => '摘要与标题质量更高；需要性能较强的设备（生成摘要时约占用 3 GB 内存）。';

  @override
  String get summariesOffValue => '无摘要 · 点按即可设置';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — 已安装，点按管理';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — 正在下载 $pct%';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — 下载已暂停（$pct%）';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — 尚未下载 · 点按即可设置';
  }

  @override
  String get groupAppearance => '外观';

  @override
  String get themeRow => '主题';

  @override
  String get themeTitle => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get groupYourData => '你的数据';

  @override
  String get backupExport => '导出与导入';

  @override
  String get backupExportDesc => '随身带走你的卡带（音频、转写文本和摘要），或再把它们带回来';

  @override
  String get aboutPrivacy => '关于与隐私';

  @override
  String get aboutPrivacyDesc => '音频绝不离开此设备';

  @override
  String get aboutTitle => '关于与隐私';

  @override
  String get aboutBody =>
      'Diktafon 的聆听、转写和摘要全都在你的手机上完成。\n\n录音、转写文本和摘要绝不离开设备。没有账户，没有云端，也没有任何分析追踪。数据离开的唯一途径，是你自己发起的备份或导出。';

  @override
  String get aboutOpenSource => 'Diktafon 是自由开源软件：';

  @override
  String get aboutPrivacyPolicy => '隐私政策';

  @override
  String get modelPickerTranscriptionTitle => '转写模型';

  @override
  String get modelPickerSummaryTitle => '摘要模型';

  @override
  String pickerInstalled(String size) {
    return '已安装 · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return '正在下载 $pct%，点按暂停';
  }

  @override
  String pickerPaused(int pct) {
    return '已暂停（$pct%），点按继续';
  }

  @override
  String pickerDownload(String size) {
    return '下载 · $size';
  }

  @override
  String needsRam(int gb) {
    return '需要 ≥ $gb GB 内存';
  }

  @override
  String storageNote(int mb) {
    return '仅在此设备上运行。模型占用的存储空间：$mb MB。';
  }

  @override
  String get deleteModelTooltip => '删除模型文件';

  @override
  String modelReadyTranscribe(String label) {
    return '$label 已就绪，正在转写等待中的备忘。';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label 已就绪，正在为等待中的备忘生成摘要。';
  }

  @override
  String downloadFailed(String label) {
    return '$label 下载失败，请检查网络连接后重试。';
  }

  @override
  String get firstRunWelcome => '欢迎使用 Diktafon';

  @override
  String get firstRunIntro =>
      '聆听、转写和摘要全都在你的手机上完成。录音、转写文本和摘要**绝不离开此设备**。没有账户，也没有云端。';

  @override
  String get firstRunSetupHeader => '首次设置';

  @override
  String get allowMicRow => '允许麦克风';

  @override
  String get micTapToGrant => '点按以授予权限';

  @override
  String get rowMicrophone => '麦克风';

  @override
  String get accessGranted => '已授予权限';

  @override
  String get micDeniedRetry => '尚未授予权限，点按可再次请求，或在系统设置中允许使用麦克风';

  @override
  String get rowTranscription => '转写';

  @override
  String get rowSummaries => '摘要';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · 已就绪';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · 正在下载 $pct%';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · 已暂停 $pct%';
  }

  @override
  String get provisionChoose => '点按选择要下载的模型';

  @override
  String get downloadsFinishInBackground => '下载会在后台继续完成。';

  @override
  String get startRecordingKey => '开始录音';

  @override
  String get backupTitle => '导出与导入';

  @override
  String get backupIntro =>
      '设备自身的备份会自动包含卡带列表、转写文本和摘要。录音文件较大，需要你主动带走：导出会把一盘卡带的音频、转写文本和摘要打包成一个 .zip 压缩包，导入压缩包即可恢复。Diktafon 不会上传任何内容。';

  @override
  String get groupExport => '导出';

  @override
  String get exportAll => '导出全部卡带';

  @override
  String get exportAllDesc => '全部内容，打包成一个压缩文件';

  @override
  String get exporting => '正在导出…';

  @override
  String exportedTo(String path) {
    return '已导出到 $path。';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已导出 $count 盘卡带到 $path。',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get groupImport => '导入';

  @override
  String get importArchive => '导入压缩包';

  @override
  String get importArchiveDesc => '从之前的导出中添加卡带';

  @override
  String get importing => '正在导入…';

  @override
  String get importDialogTitle => '导入卡带？';

  @override
  String get importDialogBody =>
      '压缩包中的卡带会添加到现有卡带旁边，不会删除或更改任何内容。导入已存在的卡带会产生一份副本，可手动删除。缺少转写文本或摘要的备忘会在导入后处理。';

  @override
  String get importAction => '导入';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos 条备忘',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: '已导入 $cassettes 盘卡带，共 $_temp0。',
    );
    return '$_temp1';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 盘卡带无法导入。',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound => '该压缩包中没有找到卡带。';

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String exportNote(String date) {
    return '由 Diktafon 导出于 $date。';
  }

  @override
  String get exportSummaryHeading => '摘要';

  @override
  String get exportNotTranscribed => '（未转写）';

  @override
  String get openSystemSettings => '设置';

  @override
  String get changeColor => '更改颜色';

  @override
  String get retranscribe => '重新转写';

  @override
  String get retranscribeTitle => '重新转写卡带？';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条备忘',
    );
    return '$_temp0将使用当前模型重新转写，摘要也会重新生成。现有转写文本和摘要（包括手动修改）将被替换。这可能需要一些时间。';
  }

  @override
  String get retranscribeAction => '重新转写';

  @override
  String get colorPickerTitle => '卡带颜色';

  @override
  String colorSwatch(int n) {
    return '颜色 $n';
  }

  @override
  String get copyTranscript => '复制转写文本';

  @override
  String get editTranscript => '编辑转写文本';

  @override
  String get editTranscriptTitle => '编辑转写文本';

  @override
  String get transcriptCopied => '转写文本已复制。';

  @override
  String get deleteMemo => '删除备忘';

  @override
  String get memoActions => '备忘操作';

  @override
  String notifDownloading(String label) {
    return '正在下载 $label';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label 已安装';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get untitledCassette => '未命名卡帶';

  @override
  String get rename => '重新命名';

  @override
  String get delete => '刪除';

  @override
  String get cancel => '取消';

  @override
  String get save => '儲存';

  @override
  String get deleteAction => '刪除';

  @override
  String get ok => '確定';

  @override
  String get back => '返回';

  @override
  String get settingsTooltip => '設定';

  @override
  String get homeEmpty => '還沒有卡帶。\n按 + 開始一捲新磁帶。';

  @override
  String get newCassette => '新卡帶';

  @override
  String get renameCassetteTitle => '重新命名卡帶';

  @override
  String get cassetteNameHint => '卡帶名稱';

  @override
  String get deleteCassetteTitle => '刪除卡帶？';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則備忘',
    );
    return '「$label」和其中的 $_temp0將被刪除。此操作無法復原。';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則備忘',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => '空白 · 點一下開啟';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · 命名中…';
  }

  @override
  String cardMetaUpdated(String memos, String date) {
    return '$memos · $date';
  }

  @override
  String cardSemantics(String label, String memos) {
    return '$label，$memos';
  }

  @override
  String todayAt(String time) {
    return '今天 $time';
  }

  @override
  String get yesterday => '昨天';

  @override
  String get deleteCassette => '刪除卡帶';

  @override
  String get blankTape => '一捲空白磁帶。\n按下紅色按鍵開始錄音。';

  @override
  String get emptyTape => '空白磁帶';

  @override
  String memoCounter(int n, int total) {
    return '備忘 $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return '正在錄製備忘 $n';
  }

  @override
  String get summaryPlaceholder => '備忘轉錄完成後，這裡會顯示卡帶摘要。';

  @override
  String get back15 => '倒轉 15 秒';

  @override
  String get forward15 => '快轉 15 秒';

  @override
  String get play => '播放';

  @override
  String get pause => '暫停';

  @override
  String get recordNewMemo => '錄製新備忘';

  @override
  String get stopRecording => '停止錄音';

  @override
  String get micPermissionNeeded => '錄音需要麥克風權限。';

  @override
  String get recordingFailed => '無法開始錄音，麥克風可能使用中。';

  @override
  String get playbackError => '播放失敗，音訊檔案可能遺失或已損毀。';

  @override
  String missingAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此裝置上找不到 $count 則備忘的音訊。',
    );
    return '$_temp0';
  }

  @override
  String get deleteMemoTitle => '刪除備忘？';

  @override
  String deleteMemoBody(int n) {
    return '備忘 $n 將被移除，磁帶會自動銜接。此操作無法復原。';
  }

  @override
  String get timelineLabel => '磁帶時間軸';

  @override
  String timelinePosition(String position, String total) {
    return '$position，共 $total';
  }

  @override
  String get noSpeech => '（無語音）';

  @override
  String get transcriptionFailedRetry => '轉錄失敗，點一下重試（音訊仍可播放）';

  @override
  String get queuedForTranscription => '排隊等待轉錄…';

  @override
  String get waitingForModel => '等待轉錄模型，請在設定中下載';

  @override
  String memoDivider(int n, String date) {
    return '備忘 $n — $date';
  }

  @override
  String get summarizing => '正在產生摘要…';

  @override
  String get summaryFailedRetry => '摘要失敗，點一下重試';

  @override
  String get transcribing => '轉錄中…';

  @override
  String get settingsTitle => '設定';

  @override
  String get groupLanguage => '語言';

  @override
  String get transcriptionLanguage => '轉錄語言';

  @override
  String get autoDetectValue => '自動偵測，每則備忘保留自己的語言';

  @override
  String get autoDetectOption => '自動偵測（依備忘）';

  @override
  String get transcriptionLanguageTitle => '轉錄語言';

  @override
  String get groupPlayback => '播放';

  @override
  String get boundaryChime => '切換提示音';

  @override
  String get boundaryChimeDesc => '磁帶轉入下一則備忘時的輕柔提示。關閉後完全無縫。';

  @override
  String get groupIntelligence => '裝置端智慧';

  @override
  String get transcriptionModel => '轉錄模型';

  @override
  String get summaryModel => '摘要模型';

  @override
  String get summariesOffOption => '無摘要';

  @override
  String get summariesOffDesc => '備忘只會轉錄成逐字稿，不產生要點、卡帶總覽或標題建議。';

  @override
  String get whisperSmallDesc => '推薦：大小與品質的最佳平衡。';

  @override
  String get whisperSmallDescCapable => '更輕更快，但準確度較低，吵雜錄音中尤其明顯。';

  @override
  String get whisperLargeDesc => '準確度更高；需要效能較強的裝置（轉錄時約需 2.5 GB 記憶體）。';

  @override
  String get whisperLargeDescCapable =>
      '推薦：準確度高出許多，吵雜環境中尤其明顯（轉錄時約需 2.5 GB 記憶體）。';

  @override
  String get llmDefaultDesc => '推薦：精簡的多語言摘要。';

  @override
  String get llm4bDesc => '摘要與標題品質更高；需要效能較強的裝置（產生摘要時約需 3 GB 記憶體）。';

  @override
  String get summariesOffValue => '無摘要 · 點一下即可設定';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — 已安裝，點一下管理';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — 下載中 $pct%';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — 下載已暫停（$pct%）';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — 尚未下載 · 點一下即可設定';
  }

  @override
  String get groupAppearance => '外觀';

  @override
  String get themeRow => '主題';

  @override
  String get themeTitle => '主題';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get groupYourData => '你的資料';

  @override
  String get backupExport => '匯出與匯入';

  @override
  String get backupExportDesc => '隨身帶走你的卡帶（音訊、逐字稿和摘要），或再把它們帶回來';

  @override
  String get aboutPrivacy => '關於與隱私';

  @override
  String get aboutPrivacyDesc => '音訊絕不會離開這部裝置';

  @override
  String get aboutTitle => '關於與隱私';

  @override
  String get aboutBody =>
      'Diktafon 的聆聽、轉錄和摘要全都在你的手機上完成。\n\n錄音、逐字稿和摘要絕不會離開裝置。沒有帳號，沒有雲端，也沒有任何分析追蹤。資料離開的唯一途徑，是你自己啟動的備份或匯出。';

  @override
  String get aboutOpenSource => 'Diktafon 是自由開源軟體：';

  @override
  String get aboutPrivacyPolicy => '隱私權政策';

  @override
  String get modelPickerTranscriptionTitle => '轉錄模型';

  @override
  String get modelPickerSummaryTitle => '摘要模型';

  @override
  String pickerInstalled(String size) {
    return '已安裝 · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return '下載中 $pct%，點一下暫停';
  }

  @override
  String pickerPaused(int pct) {
    return '已暫停（$pct%），點一下繼續';
  }

  @override
  String pickerDownload(String size) {
    return '下載 · $size';
  }

  @override
  String needsRam(int gb) {
    return '需要 ≥ $gb GB 記憶體';
  }

  @override
  String storageNote(int mb) {
    return '只在這部裝置上執行。模型佔用的儲存空間：$mb MB。';
  }

  @override
  String get deleteModelTooltip => '刪除模型檔案';

  @override
  String modelReadyTranscribe(String label) {
    return '$label 已就緒，正在轉錄等待中的備忘。';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label 已就緒，正在為等待中的備忘產生摘要。';
  }

  @override
  String downloadFailed(String label) {
    return '$label 下載失敗，請檢查網路連線後再試一次。';
  }

  @override
  String get firstRunWelcome => '歡迎使用 Diktafon';

  @override
  String get firstRunIntro =>
      '聆聽、轉錄和摘要全都在你的手機上完成。錄音、逐字稿和摘要**絕不會離開這部裝置**。沒有帳號，也沒有雲端。';

  @override
  String get firstRunSetupHeader => '首次設定';

  @override
  String get allowMicRow => '允許麥克風';

  @override
  String get micTapToGrant => '點一下授予權限';

  @override
  String get rowMicrophone => '麥克風';

  @override
  String get accessGranted => '已授予權限';

  @override
  String get micDeniedRetry => '尚未授予權限，點一下可再次詢問，或在系統設定中允許使用麥克風';

  @override
  String get rowTranscription => '轉錄';

  @override
  String get rowSummaries => '摘要';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · 已就緒';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · 下載中 $pct%';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · 已暫停 $pct%';
  }

  @override
  String get provisionChoose => '點一下選擇要下載的模型';

  @override
  String get downloadsFinishInBackground => '下載會在背景繼續完成。';

  @override
  String get startRecordingKey => '開始錄音';

  @override
  String get backupTitle => '匯出與匯入';

  @override
  String get backupIntro =>
      '裝置本身的備份會自動涵蓋卡帶清單、逐字稿和摘要。錄音檔較大，需要你自己帶走：匯出會把一捲卡帶的音訊、逐字稿和摘要打包成一個 .zip 壓縮檔，匯入壓縮檔即可還原。Diktafon 不會上傳任何內容。';

  @override
  String get groupExport => '匯出';

  @override
  String get exportAll => '匯出全部卡帶';

  @override
  String get exportAllDesc => '全部內容，打包成一個壓縮檔';

  @override
  String get exporting => '匯出中…';

  @override
  String exportedTo(String path) {
    return '已匯出至 $path。';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已匯出 $count 捲卡帶至 $path。',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get groupImport => '匯入';

  @override
  String get importArchive => '匯入壓縮檔';

  @override
  String get importArchiveDesc => '從先前的匯出加入卡帶';

  @override
  String get importing => '匯入中…';

  @override
  String get importDialogTitle => '匯入卡帶？';

  @override
  String get importDialogBody =>
      '壓縮檔中的卡帶會加到現有卡帶旁邊，不會刪除或更動任何內容。匯入已存在的卡帶會多出一份副本，可自行刪除。缺少逐字稿或摘要的備忘會在匯入後處理。';

  @override
  String get importAction => '匯入';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos 則備忘',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: '已匯入 $cassettes 捲卡帶，共 $_temp0。',
    );
    return '$_temp1';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 捲卡帶無法匯入。',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound => '這個壓縮檔中找不到卡帶。';

  @override
  String importFailed(String error) {
    return '匯入失敗：$error';
  }

  @override
  String exportNote(String date) {
    return '由 Diktafon 匯出於 $date。';
  }

  @override
  String get exportSummaryHeading => '摘要';

  @override
  String get exportNotTranscribed => '（未轉錄）';

  @override
  String get openSystemSettings => '設定';

  @override
  String get changeColor => '變更顏色';

  @override
  String get retranscribe => '重新轉錄';

  @override
  String get retranscribeTitle => '重新轉錄卡帶？';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則備忘',
    );
    return '$_temp0將以目前的模型重新轉錄，摘要也會重新產生。現有的逐字稿和摘要（包括手動修改）將被取代。這可能需要一些時間。';
  }

  @override
  String get retranscribeAction => '重新轉錄';

  @override
  String get colorPickerTitle => '卡帶顏色';

  @override
  String colorSwatch(int n) {
    return '顏色 $n';
  }

  @override
  String get copyTranscript => '複製逐字稿';

  @override
  String get editTranscript => '編輯逐字稿';

  @override
  String get editTranscriptTitle => '編輯逐字稿';

  @override
  String get transcriptCopied => '已複製逐字稿。';

  @override
  String get deleteMemo => '刪除備忘';

  @override
  String get memoActions => '備忘操作';

  @override
  String notifDownloading(String label) {
    return '正在下載 $label';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label 已安裝';
  }
}
