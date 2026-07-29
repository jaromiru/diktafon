// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get untitledCassette => 'Băng cassette chưa đặt tên';

  @override
  String get rename => 'Đổi tên';

  @override
  String get delete => 'Xóa';

  @override
  String get cancel => 'HỦY';

  @override
  String get save => 'LƯU';

  @override
  String get deleteAction => 'XÓA';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Quay lại';

  @override
  String get settingsTooltip => 'Cài đặt';

  @override
  String get homeEmpty =>
      'Chưa có băng cassette nào.\nNhấn + để bắt đầu một cuộn băng mới.';

  @override
  String get newCassette => 'Băng cassette mới';

  @override
  String get renameCassetteTitle => 'ĐỔI TÊN BĂNG CASSETTE';

  @override
  String get cassetteNameHint => 'Tên băng cassette';

  @override
  String get deleteCassetteTitle => 'XÓA BĂNG CASSETTE?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bản ghi',
    );
    return '\"$label\" và $_temp0 trong đó sẽ bị xóa. Không thể hoàn tác.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bản ghi',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'trống · nhấn để mở';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · đang tự đặt tên…';
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
    return 'hôm nay $time';
  }

  @override
  String get yesterday => 'hôm qua';

  @override
  String get deleteCassette => 'Xóa băng cassette';

  @override
  String get blankTape => 'Một cuộn băng trắng.\nNhấn phím đỏ để thu âm.';

  @override
  String get emptyTape => 'BĂNG TRẮNG';

  @override
  String memoCounter(int n, int total) {
    return 'BẢN GHI $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'ĐANG THU BẢN GHI $n';
  }

  @override
  String get summaryPlaceholder =>
      'Tóm tắt của băng cassette sẽ hiện ra sau khi các bản ghi được chép lời.';

  @override
  String get back15 => 'Lùi 15 giây';

  @override
  String get forward15 => 'Tiến 15 giây';

  @override
  String get play => 'Phát';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get recordNewMemo => 'Thu bản ghi mới';

  @override
  String get stopRecording => 'Dừng thu âm';

  @override
  String get micPermissionNeeded => 'Cần quyền micrô để thu âm.';

  @override
  String get recordingFailed =>
      'Không thể bắt đầu thu âm — micrô có thể đang được sử dụng.';

  @override
  String get playbackError =>
      'Phát lại thất bại — tệp âm thanh có thể bị thiếu hoặc hỏng.';

  @override
  String missingAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Thiếu âm thanh của $count bản ghi trên thiết bị này.',
    );
    return '$_temp0';
  }

  @override
  String get deleteMemoTitle => 'XÓA BẢN GHI?';

  @override
  String deleteMemoBody(int n) {
    return 'Bản ghi $n sẽ bị xóa và cuộn băng sẽ tự nối liền. Không thể hoàn tác.';
  }

  @override
  String get timelineLabel => 'Dòng thời gian cuộn băng';

  @override
  String timelinePosition(String position, String total) {
    return '$position trên $total';
  }

  @override
  String get noSpeech => '(không có giọng nói)';

  @override
  String get transcriptionFailedRetry =>
      'chép lời thất bại — nhấn để thử lại (âm thanh vẫn phát được)';

  @override
  String get queuedForTranscription => 'đang chờ chép lời…';

  @override
  String get waitingForModel =>
      'đang chờ mô hình chép lời — tải về trong Cài đặt';

  @override
  String memoDivider(int n, String date) {
    return 'Bản ghi $n — $date';
  }

  @override
  String get summarizing => 'đang tóm tắt…';

  @override
  String get summaryFailedRetry => 'tóm tắt thất bại — nhấn để thử lại';

  @override
  String get transcribing => 'đang chép lời…';

  @override
  String get settingsTitle => 'CÀI ĐẶT';

  @override
  String get groupLanguage => 'Ngôn ngữ';

  @override
  String get transcriptionLanguage => 'Ngôn ngữ chép lời';

  @override
  String get autoDetectValue => 'Tự nhận diện — mỗi bản ghi giữ ngôn ngữ riêng';

  @override
  String get autoDetectOption => 'Tự nhận diện (theo từng bản ghi)';

  @override
  String get transcriptionLanguageTitle => 'NGÔN NGỮ CHÉP LỜI';

  @override
  String get groupPlayback => 'Phát lại';

  @override
  String get boundaryChime => 'Âm báo chuyển bản ghi';

  @override
  String get boundaryChimeDesc =>
      'Một âm nhẹ khi băng chạy sang bản ghi kế tiếp. Tắt = liền mạch hoàn toàn.';

  @override
  String get groupIntelligence => 'Trí tuệ trên thiết bị';

  @override
  String get transcriptionModel => 'Mô hình chép lời';

  @override
  String get summaryModel => 'Mô hình tóm tắt';

  @override
  String get summariesOffOption => 'Không tóm tắt';

  @override
  String get summariesOffDesc =>
      'Bản ghi chỉ được chép lời — không có tóm tắt, tổng quan hay gợi ý tiêu đề.';

  @override
  String get whisperSmallDesc =>
      'Khuyên dùng — cân bằng tốt nhất giữa dung lượng và chất lượng.';

  @override
  String get whisperSmallDescCapable =>
      'Nhẹ và nhanh hơn — kém chính xác hơn, nhất là với bản thu ồn.';

  @override
  String get whisperLargeDesc =>
      'Chính xác hơn; cần thiết bị mạnh (~2,5 GB RAM khi chép lời).';

  @override
  String get whisperLargeDescCapable =>
      'Khuyên dùng — chính xác hơn nhiều, nhất là khi ồn (~2,5 GB RAM khi chép lời).';

  @override
  String get llmDefaultDesc => 'Khuyên dùng — tóm tắt đa ngôn ngữ, gọn nhẹ.';

  @override
  String get llm4bDesc =>
      'Tóm tắt và tiêu đề chất lượng cao hơn; cần thiết bị mạnh (~3 GB RAM khi tóm tắt).';

  @override
  String get summariesOffValue => 'Không tóm tắt · nhấn để thiết lập';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — đã cài, nhấn để quản lý';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — đang tải $pct %';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — đã tạm dừng ở $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — chưa tải về · nhấn để thiết lập';
  }

  @override
  String get groupAppearance => 'Giao diện';

  @override
  String get themeRow => 'Chủ đề';

  @override
  String get themeTitle => 'CHỦ ĐỀ';

  @override
  String get themeSystem => 'Theo hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get groupYourData => 'Dữ liệu của bạn';

  @override
  String get backupExport => 'Xuất & nhập';

  @override
  String get backupExportDesc =>
      'Mang băng cassette đi cùng bạn — âm thanh, bản chép lời và tóm tắt — hoặc đưa chúng trở lại';

  @override
  String get aboutPrivacy => 'Giới thiệu & quyền riêng tư';

  @override
  String get aboutPrivacyDesc => 'Âm thanh không bao giờ rời khỏi thiết bị này';

  @override
  String get aboutTitle => 'GIỚI THIỆU & QUYỀN RIÊNG TƯ';

  @override
  String get aboutBody =>
      'Diktafon nghe, ghi chép và tóm tắt ngay trên điện thoại của bạn.\n\nBản thu, bản chép lời và tóm tắt không bao giờ rời khỏi thiết bị. Không có tài khoản, không đám mây và không phân tích dữ liệu. Dữ liệu chỉ rời khỏi thiết bị khi chính bạn sao lưu hoặc xuất.';

  @override
  String get aboutOpenSource => 'Diktafon miễn phí và mã nguồn mở:';

  @override
  String get aboutPrivacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get modelPickerTranscriptionTitle => 'MÔ HÌNH CHÉP LỜI';

  @override
  String get modelPickerSummaryTitle => 'MÔ HÌNH TÓM TẮT';

  @override
  String pickerInstalled(String size) {
    return 'đã cài · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'đang tải $pct % — nhấn để tạm dừng';
  }

  @override
  String pickerPaused(int pct) {
    return 'tạm dừng ở $pct % — nhấn để tiếp tục';
  }

  @override
  String pickerDownload(String size) {
    return 'tải về · $size';
  }

  @override
  String needsRam(int gb) {
    return 'cần ≥ $gb GB RAM';
  }

  @override
  String storageNote(int mb) {
    return 'Chỉ chạy trên thiết bị này. Các mô hình đang chiếm $mb MB bộ nhớ.';
  }

  @override
  String get deleteModelTooltip => 'Xóa tệp mô hình';

  @override
  String modelReadyTranscribe(String label) {
    return '$label đã sẵn sàng — đang chép lời các bản ghi đang chờ.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label đã sẵn sàng — đang tóm tắt các bản ghi đang chờ.';
  }

  @override
  String downloadFailed(String label) {
    return 'Tải $label thất bại — kiểm tra kết nối rồi thử lại.';
  }

  @override
  String get firstRunWelcome => 'Chào mừng đến với Diktafon';

  @override
  String get firstRunIntro =>
      'Ứng dụng nghe, ghi chép và tóm tắt ngay trên điện thoại của bạn. Bản thu, bản chép lời và tóm tắt **không bao giờ rời khỏi thiết bị này**. Không có tài khoản và không có đám mây.';

  @override
  String get firstRunSetupHeader => 'Thiết lập lần đầu';

  @override
  String get allowMicRow => 'Cho phép micrô';

  @override
  String get micTapToGrant => 'Nhấn để cấp quyền';

  @override
  String get rowMicrophone => 'Micrô';

  @override
  String get accessGranted => 'Đã cấp quyền';

  @override
  String get micDeniedRetry =>
      'Chưa được cấp — nhấn để hỏi lại, hoặc cho phép micrô trong cài đặt hệ thống';

  @override
  String get rowTranscription => 'Chép lời';

  @override
  String get rowSummaries => 'Tóm tắt';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · sẵn sàng';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · đang tải — $pct %';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · tạm dừng — $pct %';
  }

  @override
  String get provisionChoose => 'nhấn để chọn mô hình cần tải';

  @override
  String get downloadsFinishInBackground =>
      'Quá trình tải sẽ hoàn tất trong nền.';

  @override
  String get startRecordingKey => 'BẮT ĐẦU THU ÂM';

  @override
  String get backupTitle => 'XUẤT & NHẬP';

  @override
  String get backupIntro =>
      'Sao lưu của chính thiết bị đã tự động bao gồm danh sách băng cassette, bản chép lời và tóm tắt. Bản thu âm thanh khá nặng — hãy chủ động mang theo: thao tác xuất đóng gói âm thanh, bản chép lời và tóm tắt của một băng cassette vào một tệp .zip, và nhập tệp đó sẽ đưa chúng trở lại. Diktafon không tải gì lên mạng.';

  @override
  String get groupExport => 'Xuất';

  @override
  String get exportAll => 'Xuất tất cả băng cassette';

  @override
  String get exportAllDesc => 'Mọi thứ, trong một tệp lưu trữ';

  @override
  String get exporting => 'Đang xuất…';

  @override
  String exportedTo(String path) {
    return 'Đã xuất vào $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã xuất $count băng cassette vào $path.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'Xuất thất bại: $error';
  }

  @override
  String get groupImport => 'Nhập';

  @override
  String get importArchive => 'Nhập tệp lưu trữ';

  @override
  String get importArchiveDesc => 'Thêm băng cassette từ một lần xuất trước';

  @override
  String get importing => 'Đang nhập…';

  @override
  String get importDialogTitle => 'NHẬP BĂNG CASSETTE?';

  @override
  String get importDialogBody =>
      'Các băng cassette trong tệp sẽ được thêm bên cạnh những băng bạn đang có — không gì bị xóa hay thay đổi. Nhập một băng đã có sẵn sẽ tạo thêm một bản sao, bạn có thể tự xóa. Các bản ghi thiếu bản chép lời hoặc tóm tắt sẽ được xử lý sau khi nhập.';

  @override
  String get importAction => 'NHẬP';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos bản ghi',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: 'Đã nhập $cassettes băng cassette với $_temp0.',
    );
    return '$_temp1';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Không thể nhập $count băng cassette.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound =>
      'Không tìm thấy băng cassette nào trong tệp đó.';

  @override
  String importFailed(String error) {
    return 'Nhập thất bại: $error';
  }

  @override
  String exportNote(String date) {
    return 'Đã xuất từ Diktafon ngày $date.';
  }

  @override
  String get exportSummaryHeading => 'Tóm tắt';

  @override
  String get exportNotTranscribed => '(chưa chép lời)';

  @override
  String get openSystemSettings => 'CÀI ĐẶT';

  @override
  String get changeColor => 'Đổi màu';

  @override
  String get retranscribe => 'Chép lời lại';

  @override
  String get retranscribeTitle => 'CHÉP LỜI LẠI BĂNG CASSETTE?';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bản ghi',
    );
    return '$_temp0 sẽ được chép lời lại bằng các mô hình hiện tại và bản tóm tắt sẽ được tạo lại. Bản chép lời và tóm tắt hiện có sẽ bị thay thế. Việc này có thể mất một lúc.';
  }

  @override
  String get retranscribeAction => 'CHÉP LỜI LẠI';

  @override
  String get colorPickerTitle => 'MÀU BĂNG CASSETTE';

  @override
  String colorSwatch(int n) {
    return 'Màu $n';
  }

  @override
  String get copyTranscript => 'Sao chép bản chép lời';

  @override
  String get transcriptCopied => 'Đã sao chép bản chép lời.';

  @override
  String get deleteMemo => 'Xóa bản ghi';

  @override
  String get memoActions => 'Thao tác với bản ghi';

  @override
  String notifDownloading(String label) {
    return 'Đang tải $label';
  }

  @override
  String notifModelInstalled(String label) {
    return 'Đã cài $label';
  }

  @override
  String get notifRecording => 'Đang thu âm';

  @override
  String get notifRecordingChannel => 'Thu âm';
}
