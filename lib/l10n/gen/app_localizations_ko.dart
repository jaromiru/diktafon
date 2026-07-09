// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get untitledCassette => '제목 없는 카세트';

  @override
  String get rename => '이름 변경';

  @override
  String get delete => '삭제';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get deleteAction => '삭제';

  @override
  String get ok => '확인';

  @override
  String get back => '뒤로';

  @override
  String get settingsTooltip => '설정';

  @override
  String get homeEmpty => '아직 카세트가 없습니다.\n+를 눌러 새 테이프를 시작하세요.';

  @override
  String get newCassette => '새 카세트';

  @override
  String get renameCassetteTitle => '카세트 이름 변경';

  @override
  String get cassetteNameHint => '카세트 이름';

  @override
  String get deleteCassetteTitle => '카세트를 삭제할까요?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '메모 $count개',
    );
    return '“$label” 및 $_temp0가 삭제됩니다. 되돌릴 수 없습니다.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '메모 $count개',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => '비어 있음 · 눌러서 열기';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · 이름 짓는 중…';
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
    return '오늘 $time';
  }

  @override
  String get yesterday => '어제';

  @override
  String get deleteCassette => '카세트 삭제';

  @override
  String get blankTape => '빈 테이프입니다.\n빨간 키를 눌러 녹음하세요.';

  @override
  String get emptyTape => '빈 테이프';

  @override
  String memoCounter(int n, int total) {
    return '메모 $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return '메모 $n 녹음 중';
  }

  @override
  String get summaryPlaceholder => '메모가 텍스트로 변환되면 카세트 요약이 표시됩니다.';

  @override
  String get back15 => '15초 뒤로';

  @override
  String get forward15 => '15초 앞으로';

  @override
  String get play => '재생';

  @override
  String get pause => '일시정지';

  @override
  String get recordNewMemo => '새 메모 녹음';

  @override
  String get stopRecording => '녹음 중지';

  @override
  String get micPermissionNeeded => '녹음하려면 마이크 권한이 필요합니다.';

  @override
  String get deleteMemoTitle => '메모를 삭제할까요?';

  @override
  String deleteMemoBody(int n) {
    return '메모 $n이(가) 삭제되고 테이프의 빈자리는 이어집니다. 되돌릴 수 없습니다.';
  }

  @override
  String get timelineLabel => '테이프 타임라인';

  @override
  String timelinePosition(String position, String total) {
    return '$total 중 $position';
  }

  @override
  String get noSpeech => '(음성 없음)';

  @override
  String get transcriptionFailedRetry =>
      '텍스트 변환 실패 — 눌러서 다시 시도 (오디오는 계속 재생됩니다)';

  @override
  String get queuedForTranscription => '텍스트 변환 대기 중…';

  @override
  String get waitingForModel => '텍스트 변환 모델 대기 중 — 설정에서 다운로드하세요';

  @override
  String memoDivider(int n, String date) {
    return '메모 $n — $date';
  }

  @override
  String get summarizing => '요약 중…';

  @override
  String get summaryFailedRetry => '요약 실패 — 눌러서 다시 시도';

  @override
  String get transcribing => '텍스트로 변환 중…';

  @override
  String get settingsTitle => '설정';

  @override
  String get groupLanguage => '언어';

  @override
  String get transcriptionLanguage => '텍스트 변환 언어';

  @override
  String get autoDetectValue => '자동 감지 — 메모마다 언어를 따로 기억합니다';

  @override
  String get autoDetectOption => '자동 감지 (메모별)';

  @override
  String get transcriptionLanguageTitle => '텍스트 변환 언어';

  @override
  String get groupPlayback => '재생';

  @override
  String get boundaryChime => '경계 알림음';

  @override
  String get boundaryChimeDesc =>
      '테이프가 다음 메모로 넘어갈 때 나는 부드러운 신호음. 끄면 완전히 이어서 재생됩니다.';

  @override
  String get groupIntelligence => '온디바이스 인텔리전스';

  @override
  String get transcriptionModel => '텍스트 변환 모델';

  @override
  String get summaryModel => '요약 모델';

  @override
  String get summariesRow => '요약';

  @override
  String get summariesRowDesc => '메모 요약과 카세트 개요를 기기에서 생성합니다';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — 설치됨, 눌러서 관리';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — 다운로드 중 $pct %';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — 다운로드 일시정지됨 ($pct %)';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — 아직 다운로드되지 않음 · 눌러서 설정';
  }

  @override
  String get groupAppearance => '화면';

  @override
  String get themeRow => '테마';

  @override
  String get themeTitle => '테마';

  @override
  String get themeSystem => '시스템 설정';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get groupYourData => '내 데이터';

  @override
  String get backupExport => '내보내기 및 가져오기';

  @override
  String get backupExportDesc => '카세트를 가지고 가세요 — 오디오, 변환 텍스트, 요약 — 또는 다시 가져오세요';

  @override
  String get aboutPrivacy => '정보 및 개인정보';

  @override
  String get aboutPrivacyDesc => '오디오는 이 기기를 절대 벗어나지 않습니다';

  @override
  String get aboutTitle => '정보 및 개인정보';

  @override
  String get aboutBody =>
      'Diktafon은 휴대폰 안에서 바로 듣고, 적고, 요약합니다.\n\n녹음, 변환 텍스트, 요약은 기기를 절대 벗어나지 않습니다. 계정도, 클라우드도, 분석 도구도 없습니다. 데이터가 나가는 유일한 길은 직접 시작한 백업이나 내보내기뿐입니다.';

  @override
  String get aboutOpenSource => 'Diktafon은 무료 오픈 소스입니다:';

  @override
  String get modelPickerTranscriptionTitle => '텍스트 변환 모델';

  @override
  String get modelPickerSummaryTitle => '요약 모델';

  @override
  String pickerInstalled(String size) {
    return '설치됨 · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return '다운로드 중 $pct % — 탭하여 일시정지';
  }

  @override
  String pickerPaused(int pct) {
    return '$pct %에서 일시정지됨 — 탭하여 재개';
  }

  @override
  String pickerDownload(String size) {
    return '다운로드 · $size';
  }

  @override
  String needsRam(int gb) {
    return 'RAM $gb GB 이상 필요';
  }

  @override
  String storageNote(int mb) {
    return '이 기기에서만 실행됩니다. 모델이 차지하는 저장 공간: $mb MB.';
  }

  @override
  String get deleteModelTooltip => '모델 파일 삭제';

  @override
  String modelReadyTranscribe(String label) {
    return '$label 준비 완료 — 대기 중인 메모를 변환합니다.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label 준비 완료 — 대기 중인 메모를 요약합니다.';
  }

  @override
  String downloadFailed(String label) {
    return '$label 다운로드 실패 — 연결을 확인하고 다시 시도하세요.';
  }

  @override
  String get firstRunWelcome => 'Diktafon에 오신 것을 환영합니다';

  @override
  String get firstRunIntro =>
      '휴대폰 안에서 바로 듣고, 적고, 요약합니다. 녹음, 변환 텍스트, 요약은 **이 기기를 절대 벗어나지 않습니다**. 계정도 클라우드도 없습니다.';

  @override
  String get firstRunSetupHeader => '처음 설정';

  @override
  String get allowMicRow => '마이크 허용';

  @override
  String get micTapToGrant => '눌러서 권한 부여';

  @override
  String get rowMicrophone => '마이크';

  @override
  String get accessGranted => '권한 허용됨';

  @override
  String get micDeniedRetry => '허용되지 않음 — 눌러서 다시 요청하거나 시스템 설정에서 마이크를 허용하세요';

  @override
  String get rowTranscription => '텍스트 변환';

  @override
  String get rowSummaries => '요약';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · 준비 완료';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · 다운로드 중 — $pct %';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · 일시정지됨 — $pct %';
  }

  @override
  String get provisionChoose => '눌러서 다운로드할 모델 선택';

  @override
  String get downloadsFinishInBackground => '다운로드는 백그라운드에서 계속됩니다.';

  @override
  String get startRecordingKey => '녹음 시작';

  @override
  String get backupTitle => '내보내기 및 가져오기';

  @override
  String get backupIntro =>
      '기기 자체 백업이 카세트 목록, 변환 텍스트, 요약을 자동으로 보관합니다. 녹음 파일은 용량이 큽니다 — 직접 챙기세요: 내보내기는 카세트의 오디오, 변환 텍스트, 요약을 .zip 아카이브 하나로 묶고, 아카이브를 가져오면 다시 복원됩니다. Diktafon은 아무것도 업로드하지 않습니다.';

  @override
  String get groupExport => '내보내기';

  @override
  String get exportAll => '모든 카세트 내보내기';

  @override
  String get exportAllDesc => '전부 아카이브 파일 하나로';

  @override
  String get exporting => '내보내는 중…';

  @override
  String exportedTo(String path) {
    return '$path에 내보냈습니다.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '카세트 $count개를 $path에 내보냈습니다.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String get groupImport => '가져오기';

  @override
  String get importArchive => '아카이브 가져오기';

  @override
  String get importArchiveDesc => '이전 내보내기에서 카세트를 추가합니다';

  @override
  String get importing => '가져오는 중…';

  @override
  String get importDialogTitle => '카세트를 가져올까요?';

  @override
  String get importDialogBody =>
      '아카이브의 카세트는 기존 카세트 옆에 추가됩니다 — 아무것도 삭제되거나 바뀌지 않습니다. 이미 있는 카세트를 가져오면 사본이 하나 더 생기며, 직접 삭제할 수 있습니다. 변환 텍스트나 요약이 없는 메모는 가져온 뒤 처리됩니다.';

  @override
  String get importAction => '가져오기';

  @override
  String importedResult(int cassettes, int memos) {
    return '카세트 $cassettes개와 메모 $memos개를 가져왔습니다.';
  }

  @override
  String importFailures(int count) {
    return '카세트 $count개를 가져오지 못했습니다.';
  }

  @override
  String get importNothingFound => '이 아카이브에는 카세트가 없습니다.';

  @override
  String importFailed(String error) {
    return '가져오기 실패: $error';
  }

  @override
  String exportNote(String date) {
    return '$date에 Diktafon에서 내보냄.';
  }

  @override
  String get exportSummaryHeading => '요약';

  @override
  String get exportNotTranscribed => '(변환되지 않음)';

  @override
  String get openSystemSettings => '설정';

  @override
  String get changeColor => '색상 변경';

  @override
  String get retranscribe => '다시 변환';

  @override
  String get retranscribeTitle => '카세트를 다시 변환할까요?';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '메모 $count개',
    );
    return '$_temp0를 현재 모델로 다시 텍스트로 변환하고 요약을 새로 만듭니다. 기존 변환 텍스트와 요약은 교체됩니다. 시간이 걸릴 수 있습니다.';
  }

  @override
  String get retranscribeAction => '다시 변환';

  @override
  String get colorPickerTitle => '카세트 색상';

  @override
  String colorSwatch(int n) {
    return '색상 $n';
  }

  @override
  String get copyTranscript => '변환 텍스트 복사';

  @override
  String get transcriptCopied => '변환 텍스트가 복사되었습니다.';

  @override
  String get deleteMemo => '메모 삭제';

  @override
  String get memoActions => '메모 동작';

  @override
  String get cleanupRow => '변환 텍스트 다듬기';

  @override
  String get cleanupRowDesc => '요약 모델이 새 변환 텍스트를 다듬습니다 — 맞춤법과 인식 오류';

  @override
  String notifDownloading(String label) {
    return '$label 다운로드 중';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label 설치됨';
  }
}
