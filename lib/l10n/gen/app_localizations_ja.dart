// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get untitledCassette => '無題のカセット';

  @override
  String get rename => '名前を変更';

  @override
  String get delete => '削除';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get deleteAction => '削除';

  @override
  String get ok => 'OK';

  @override
  String get back => '戻る';

  @override
  String get settingsTooltip => '設定';

  @override
  String get homeEmpty => 'まだカセットがありません。\n+ を押して新しいテープを始めましょう。';

  @override
  String get newCassette => '新しいカセット';

  @override
  String get renameCassetteTitle => 'カセット名を変更';

  @override
  String get cassetteNameHint => 'カセット名';

  @override
  String get deleteCassetteTitle => 'カセットを削除しますか？';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のメモ',
    );
    return '「$label」と$_temp0が削除されます。この操作は元に戻せません。';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のメモ',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'メモなし・タップで開く';

  @override
  String cardMetaNaming(String memos) {
    return '$memos・名前を考え中…';
  }

  @override
  String cardMetaUpdated(String memos, String date) {
    return '$memos・$date';
  }

  @override
  String cardSemantics(String label, String memos) {
    return '$label、$memos';
  }

  @override
  String todayAt(String time) {
    return '今日 $time';
  }

  @override
  String get yesterday => '昨日';

  @override
  String get deleteCassette => 'カセットを削除';

  @override
  String get blankTape => '空のテープです。\n赤いキーを押して録音しましょう。';

  @override
  String get emptyTape => '空のテープ';

  @override
  String memoCounter(int n, int total) {
    return 'メモ $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'メモ $n 録音中';
  }

  @override
  String get summaryPlaceholder => 'カセットの要約は、メモが文字起こしされると表示されます。';

  @override
  String get back15 => '15秒戻る';

  @override
  String get forward15 => '15秒進む';

  @override
  String get play => '再生';

  @override
  String get pause => '一時停止';

  @override
  String get recordNewMemo => '新しいメモを録音';

  @override
  String get stopRecording => '録音を停止';

  @override
  String get micPermissionNeeded => '録音にはマイクの権限が必要です。';

  @override
  String get recordingFailed => '録音を開始できませんでした。マイクが使用中の可能性があります。';

  @override
  String get playbackError => '再生に失敗しました。音声ファイルが見つからないか、破損している可能性があります。';

  @override
  String missingAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のメモの音声がこの端末にありません。',
    );
    return '$_temp0';
  }

  @override
  String get deleteMemoTitle => 'メモを削除しますか？';

  @override
  String deleteMemoBody(int n) {
    return 'メモ $n が削除され、テープの空いた部分は詰められます。この操作は元に戻せません。';
  }

  @override
  String get timelineLabel => 'テープのタイムライン';

  @override
  String timelinePosition(String position, String total) {
    return '$total 中 $position';
  }

  @override
  String get noSpeech => '（発話なし）';

  @override
  String get transcriptionFailedRetry => '文字起こしに失敗しました — タップで再試行（音声は再生できます）';

  @override
  String get queuedForTranscription => '文字起こしを待機中…';

  @override
  String get waitingForModel => '文字起こしモデルを待っています — 設定からダウンロードしてください';

  @override
  String memoDivider(int n, String date) {
    return 'メモ $n — $date';
  }

  @override
  String get summarizing => '要約中…';

  @override
  String get summaryFailedRetry => '要約に失敗しました — タップで再試行';

  @override
  String get transcribing => '文字起こし中…';

  @override
  String get settingsTitle => '設定';

  @override
  String get groupLanguage => '言語';

  @override
  String get transcriptionLanguage => '文字起こしの言語';

  @override
  String get autoDetectValue => '自動検出 — メモごとに言語を判別します';

  @override
  String get autoDetectOption => '自動検出（メモごと）';

  @override
  String get transcriptionLanguageTitle => '文字起こしの言語';

  @override
  String get groupPlayback => '再生';

  @override
  String get boundaryChime => '区切りのチャイム';

  @override
  String get boundaryChimeDesc =>
      'テープが次のメモに進むときに鳴る、控えめな合図の音です。オフにすると完全に切れ目なく再生されます。';

  @override
  String get groupIntelligence => 'オンデバイスAI';

  @override
  String get transcriptionModel => '文字起こしモデル';

  @override
  String get summaryModel => '要約モデル';

  @override
  String get summariesOffOption => '要約なし';

  @override
  String get summariesOffDesc => 'メモは文字起こしのみ行われ、要点・概要・タイトル候補は作成されません。';

  @override
  String get whisperSmallDesc => 'おすすめ — サイズと品質のバランスが最適です。';

  @override
  String get whisperSmallDescCapable => 'より軽量で高速ですが、精度は下がります。特に騒がしい録音で差が出ます。';

  @override
  String get whisperLargeDesc =>
      'より高精度。高性能な端末が必要です（文字起こし中に約 2.5 GB の RAM を使用）。';

  @override
  String get whisperLargeDescCapable =>
      'おすすめ — はるかに高精度で、特に騒音下で強みがあります（文字起こし中に約 2.5 GB の RAM を使用）。';

  @override
  String get llmDefaultDesc => 'おすすめ — コンパクトな多言語対応の要約。';

  @override
  String get llm4bDesc => 'より高品質な要約とタイトル。高性能な端末が必要です（要約中に約 3 GB の RAM を使用）。';

  @override
  String get summariesOffValue => '要約なし・タップで設定';

  @override
  String modelInstalled(String label, String size) {
    return '$label・$size — インストール済み、タップで管理';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — ダウンロード中 $pct%';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — ダウンロード一時停止中（$pct%）';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — 未ダウンロード・タップで設定';
  }

  @override
  String get groupAppearance => '外観';

  @override
  String get themeRow => 'テーマ';

  @override
  String get themeTitle => 'テーマ';

  @override
  String get themeSystem => 'システムに従う';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get groupYourData => 'データ';

  @override
  String get backupExport => 'エクスポートとインポート';

  @override
  String get backupExportDesc => '音声・文字起こし・要約ごとカセットを持ち出したり、戻したりできます';

  @override
  String get aboutPrivacy => 'アプリ情報とプライバシー';

  @override
  String get aboutPrivacyDesc => '音声がこの端末の外に出ることはありません';

  @override
  String get aboutTitle => 'アプリ情報とプライバシー';

  @override
  String get aboutBody =>
      'Diktafon は、聞き取りも、書き起こしも、要約も、すべてお使いのスマートフォンの中で行います。\n\n録音・文字起こし・要約が端末の外に出ることはありません。アカウントも、クラウドも、分析ツールもありません。データが外に出るのは、ご自身で行うバックアップやエクスポートだけです。';

  @override
  String get aboutOpenSource => 'Diktafon は無料のオープンソースソフトウェアです：';

  @override
  String get aboutPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get modelPickerTranscriptionTitle => '文字起こしモデル';

  @override
  String get modelPickerSummaryTitle => '要約モデル';

  @override
  String pickerInstalled(String size) {
    return 'インストール済み・$size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'ダウンロード中 $pct% — タップで一時停止';
  }

  @override
  String pickerPaused(int pct) {
    return '$pct%で一時停止中 — タップで再開';
  }

  @override
  String pickerDownload(String size) {
    return 'ダウンロード・$size';
  }

  @override
  String needsRam(int gb) {
    return 'RAM $gb GB 以上が必要';
  }

  @override
  String storageNote(int mb) {
    return 'モデルはこの端末上でのみ動作します。モデルの使用容量：$mb MB。';
  }

  @override
  String get deleteModelTooltip => 'モデルファイルを削除';

  @override
  String modelReadyTranscribe(String label) {
    return '$label の準備ができました — 待機中のメモを文字起こしします。';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label の準備ができました — 待機中のメモを要約します。';
  }

  @override
  String downloadFailed(String label) {
    return '$label のダウンロードに失敗しました — 接続を確認して、もう一度お試しください。';
  }

  @override
  String get firstRunWelcome => 'Diktafon へようこそ';

  @override
  String get firstRunIntro =>
      '聞き取りも、書き起こしも、要約も、すべてお使いのスマートフォンの中で行われます。録音・文字起こし・要約が**この端末の外に出ることはありません**。アカウントもクラウドもありません。';

  @override
  String get firstRunSetupHeader => '初回セットアップ';

  @override
  String get allowMicRow => 'マイクを許可';

  @override
  String get micTapToGrant => 'タップして許可';

  @override
  String get rowMicrophone => 'マイク';

  @override
  String get accessGranted => '許可済み';

  @override
  String get micDeniedRetry =>
      '許可されていません — タップしてもう一度リクエストするか、システム設定でマイクを許可してください';

  @override
  String get rowTranscription => '文字起こし';

  @override
  String get rowSummaries => '要約';

  @override
  String provisionReady(String label, String size) {
    return '$label・$size・準備完了';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label・$size・ダウンロード中 — $pct%';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label・$size・一時停止中 — $pct%';
  }

  @override
  String get provisionChoose => 'タップしてダウンロードするモデルを選択';

  @override
  String get downloadsFinishInBackground => 'ダウンロードはバックグラウンドで完了します。';

  @override
  String get startRecordingKey => '録音を開始';

  @override
  String get backupTitle => 'エクスポートとインポート';

  @override
  String get backupIntro =>
      'カセットの一覧・文字起こし・要約は、端末標準のバックアップで自動的に保護されます。録音音声はサイズが大きいため、明示的に持ち出します。エクスポートすると、カセットの音声・文字起こし・要約が 1 つの .zip アーカイブにまとまり、そのアーカイブをインポートすれば元に戻せます。Diktafon が何かをアップロードすることはありません。';

  @override
  String get groupExport => 'エクスポート';

  @override
  String get exportAll => 'すべてのカセットをエクスポート';

  @override
  String get exportAllDesc => 'すべてを 1 つのアーカイブファイルに';

  @override
  String get exporting => 'エクスポート中…';

  @override
  String exportedTo(String path) {
    return '$path にエクスポートしました。';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 本のカセットを $path にエクスポートしました。',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'エクスポートに失敗しました：$error';
  }

  @override
  String get groupImport => 'インポート';

  @override
  String get importArchive => 'アーカイブをインポート';

  @override
  String get importArchiveDesc => '以前のエクスポートからカセットを追加します';

  @override
  String get importing => 'インポート中…';

  @override
  String get importDialogTitle => 'カセットをインポートしますか？';

  @override
  String get importDialogBody =>
      'アーカイブ内のカセットは、今あるカセットに並べて追加されます。何も削除・変更されません。すでにあるカセットをインポートすると 2 つ目のコピーができますが、手動で削除できます。文字起こしや要約のないメモは、インポート後に処理されます。';

  @override
  String get importAction => 'インポート';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: 'メモ $memos 件',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: '$cassettes 本のカセット（$_temp0）をインポートしました。',
    );
    return '$_temp1';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 本のカセットをインポートできませんでした。',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound => 'そのアーカイブにカセットは見つかりませんでした。';

  @override
  String importFailed(String error) {
    return 'インポートに失敗しました：$error';
  }

  @override
  String exportNote(String date) {
    return '$date に Diktafon からエクスポートされました。';
  }

  @override
  String get exportSummaryHeading => '要約';

  @override
  String get exportNotTranscribed => '（文字起こしなし）';

  @override
  String get openSystemSettings => '設定';

  @override
  String get changeColor => '色を変更';

  @override
  String get retranscribe => '文字起こしをやり直す';

  @override
  String get retranscribeTitle => 'カセットを文字起こしし直しますか？';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のメモ',
    );
    return '$_temp0を現在のモデルで文字起こしし直し、要約を作り直します。既存の文字起こしと要約は置き換えられます。しばらく時間がかかることがあります。';
  }

  @override
  String get retranscribeAction => 'やり直す';

  @override
  String get colorPickerTitle => 'カセットの色';

  @override
  String colorSwatch(int n) {
    return '色 $n';
  }

  @override
  String get copyTranscript => '文字起こしをコピー';

  @override
  String get transcriptCopied => '文字起こしをコピーしました。';

  @override
  String get deleteMemo => 'メモを削除';

  @override
  String get memoActions => 'メモの操作';

  @override
  String notifDownloading(String label) {
    return '$label をダウンロード中';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label をインストールしました';
  }

  @override
  String get notifRecording => '録音中';

  @override
  String get notifRecordingChannel => '録音';
}
