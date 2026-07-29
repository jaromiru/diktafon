// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get untitledCassette => 'Kaset tanpa judul';

  @override
  String get rename => 'Ganti nama';

  @override
  String get delete => 'Hapus';

  @override
  String get cancel => 'BATAL';

  @override
  String get save => 'SIMPAN';

  @override
  String get deleteAction => 'HAPUS';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Kembali';

  @override
  String get settingsTooltip => 'Pengaturan';

  @override
  String get homeEmpty => 'Belum ada kaset.\nTekan + untuk memulai pita baru.';

  @override
  String get newCassette => 'Kaset baru';

  @override
  String get renameCassetteTitle => 'GANTI NAMA KASET';

  @override
  String get cassetteNameHint => 'Nama kaset';

  @override
  String get deleteCassetteTitle => 'HAPUS KASET?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count memo',
    );
    return '\"$label\" dan $_temp0 di dalamnya akan dihapus. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count memo',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'kosong · tekan untuk membuka';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · menamai dirinya…';
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
    return 'hari ini $time';
  }

  @override
  String get yesterday => 'kemarin';

  @override
  String get deleteCassette => 'Hapus kaset';

  @override
  String get blankTape => 'Pita kosong.\nTekan tombol merah untuk merekam.';

  @override
  String get emptyTape => 'PITA KOSONG';

  @override
  String memoCounter(int n, int total) {
    return 'MEMO $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'MEREKAM MEMO $n';
  }

  @override
  String get summaryPlaceholder =>
      'Ringkasan kaset muncul setelah memo ditranskripsi.';

  @override
  String get back15 => 'Mundur 15 detik';

  @override
  String get forward15 => 'Maju 15 detik';

  @override
  String get play => 'Putar';

  @override
  String get pause => 'Jeda';

  @override
  String get recordNewMemo => 'Rekam memo baru';

  @override
  String get stopRecording => 'Hentikan perekaman';

  @override
  String get micPermissionNeeded => 'Izin mikrofon diperlukan untuk merekam.';

  @override
  String get recordingFailed =>
      'Tidak dapat memulai perekaman — mikrofon mungkin sedang dipakai.';

  @override
  String get playbackError =>
      'Pemutaran gagal — file audio mungkin hilang atau rusak.';

  @override
  String missingAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Audio untuk $count memo tidak ada di perangkat ini.',
    );
    return '$_temp0';
  }

  @override
  String get deleteMemoTitle => 'HAPUS MEMO?';

  @override
  String deleteMemoBody(int n) {
    return 'Memo $n akan dihapus dan pita menutup celahnya. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get timelineLabel => 'Linimasa pita';

  @override
  String timelinePosition(String position, String total) {
    return '$position dari $total';
  }

  @override
  String get noSpeech => '(tidak ada ucapan)';

  @override
  String get transcriptionFailedRetry =>
      'transkripsi gagal — ketuk untuk mencoba lagi (audio tetap bisa diputar)';

  @override
  String get queuedForTranscription => 'dalam antrean transkripsi…';

  @override
  String get waitingForModel =>
      'menunggu model transkripsi — unduh di Pengaturan';

  @override
  String memoDivider(int n, String date) {
    return 'Memo $n — $date';
  }

  @override
  String get summarizing => 'meringkas…';

  @override
  String get summaryFailedRetry => 'ringkasan gagal — ketuk untuk mencoba lagi';

  @override
  String get transcribing => 'mentranskripsi…';

  @override
  String get settingsTitle => 'PENGATURAN';

  @override
  String get groupLanguage => 'Bahasa';

  @override
  String get transcriptionLanguage => 'Bahasa transkripsi';

  @override
  String get autoDetectValue =>
      'Deteksi otomatis — tiap memo memakai bahasanya sendiri';

  @override
  String get autoDetectOption => 'Deteksi otomatis (per memo)';

  @override
  String get transcriptionLanguageTitle => 'BAHASA TRANSKRIPSI';

  @override
  String get groupPlayback => 'Pemutaran';

  @override
  String get boundaryChime => 'Nada batas memo';

  @override
  String get boundaryChimeDesc =>
      'Isyarat lembut saat pita berpindah ke memo berikutnya. Nonaktif = sepenuhnya mulus.';

  @override
  String get groupIntelligence => 'Kecerdasan di perangkat';

  @override
  String get transcriptionModel => 'Model transkripsi';

  @override
  String get summaryModel => 'Model ringkasan';

  @override
  String get summariesOffOption => 'Tanpa ringkasan';

  @override
  String get summariesOffDesc =>
      'Memo hanya ditranskripsi — tanpa intisari, ikhtisar, atau usulan judul.';

  @override
  String get whisperSmallDesc =>
      'Disarankan — keseimbangan ukuran/kualitas terbaik.';

  @override
  String get whisperSmallDescCapable =>
      'Lebih ringan dan cepat — kurang akurat, terutama pada rekaman bising.';

  @override
  String get whisperLargeDesc =>
      'Akurasi lebih tinggi; butuh perangkat mumpuni (~2,5 GB RAM saat transkripsi).';

  @override
  String get whisperLargeDescCapable =>
      'Disarankan — jauh lebih akurat, terutama di tempat bising (~2,5 GB RAM saat transkripsi).';

  @override
  String get llmDefaultDesc => 'Disarankan — ringkasan multibahasa yang padat.';

  @override
  String get llm4bDesc =>
      'Ringkasan & judul berkualitas lebih tinggi; butuh perangkat mumpuni (~3 GB RAM saat meringkas).';

  @override
  String get summariesOffValue => 'Tanpa ringkasan · ketuk untuk menyiapkan';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — terpasang, ketuk untuk mengelola';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — mengunduh $pct %';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — unduhan dijeda di $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — belum diunduh · ketuk untuk menyiapkan';
  }

  @override
  String get groupAppearance => 'Tampilan';

  @override
  String get themeRow => 'Tema';

  @override
  String get themeTitle => 'TEMA';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get groupYourData => 'Data Anda';

  @override
  String get backupExport => 'Ekspor & impor';

  @override
  String get backupExportDesc =>
      'Bawa kaset Anda ke mana pun — audio, transkrip, dan ringkasan — atau kembalikan lagi';

  @override
  String get aboutPrivacy => 'Tentang & privasi';

  @override
  String get aboutPrivacyDesc =>
      'Audio tidak pernah meninggalkan perangkat ini';

  @override
  String get aboutTitle => 'TENTANG & PRIVASI';

  @override
  String get aboutBody =>
      'Diktafon mendengarkan, menulis, dan meringkas langsung di ponsel Anda.\n\nRekaman, transkrip, dan ringkasan tidak pernah meninggalkan perangkat. Tidak ada akun, tidak ada cloud, dan tidak ada analitik. Data hanya keluar lewat pencadangan atau ekspor yang Anda lakukan sendiri.';

  @override
  String get aboutOpenSource => 'Diktafon gratis dan bersumber terbuka:';

  @override
  String get aboutPrivacyPolicy => 'Kebijakan privasi';

  @override
  String get modelPickerTranscriptionTitle => 'MODEL TRANSKRIPSI';

  @override
  String get modelPickerSummaryTitle => 'MODEL RINGKASAN';

  @override
  String pickerInstalled(String size) {
    return 'terpasang · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'mengunduh $pct % — ketuk untuk menjeda';
  }

  @override
  String pickerPaused(int pct) {
    return 'dijeda di $pct % — ketuk untuk melanjutkan';
  }

  @override
  String pickerDownload(String size) {
    return 'unduh · $size';
  }

  @override
  String needsRam(int gb) {
    return 'butuh RAM ≥ $gb GB';
  }

  @override
  String storageNote(int mb) {
    return 'Berjalan di perangkat ini saja. Penyimpanan yang dipakai model: $mb MB.';
  }

  @override
  String get deleteModelTooltip => 'Hapus file model';

  @override
  String modelReadyTranscribe(String label) {
    return '$label siap — mentranskripsi memo yang menunggu.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label siap — meringkas memo yang menunggu.';
  }

  @override
  String downloadFailed(String label) {
    return 'Unduhan $label gagal — periksa koneksi Anda dan coba lagi.';
  }

  @override
  String get firstRunWelcome => 'Selamat datang di Diktafon';

  @override
  String get firstRunIntro =>
      'Aplikasi ini mendengarkan, menulis, dan meringkas langsung di ponsel Anda. Rekaman, transkrip, dan ringkasan **tidak pernah meninggalkan perangkat ini**. Tidak ada akun dan tidak ada cloud.';

  @override
  String get firstRunSetupHeader => 'Penyiapan awal';

  @override
  String get allowMicRow => 'Izinkan mikrofon';

  @override
  String get micTapToGrant => 'Ketuk untuk memberi izin';

  @override
  String get rowMicrophone => 'Mikrofon';

  @override
  String get accessGranted => 'Akses diberikan';

  @override
  String get micDeniedRetry =>
      'Belum diizinkan — ketuk untuk meminta lagi, atau izinkan mikrofon di pengaturan sistem';

  @override
  String get rowTranscription => 'Transkripsi';

  @override
  String get rowSummaries => 'Ringkasan';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · siap';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · mengunduh — $pct %';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · dijeda — $pct %';
  }

  @override
  String get provisionChoose => 'ketuk untuk memilih model yang akan diunduh';

  @override
  String get downloadsFinishInBackground =>
      'Unduhan selesai di latar belakang.';

  @override
  String get startRecordingKey => 'MULAI MEREKAM';

  @override
  String get backupTitle => 'EKSPOR & IMPOR';

  @override
  String get backupIntro =>
      'Pencadangan bawaan perangkat sudah otomatis mencakup daftar kaset, transkrip, dan ringkasan. Rekaman audio berukuran besar — bawalah secara eksplisit: ekspor mengemas audio, transkrip, dan ringkasan sebuah kaset ke dalam satu arsip .zip, dan mengimpor arsip akan mengembalikannya. Diktafon tidak mengunggah apa pun.';

  @override
  String get groupExport => 'Ekspor';

  @override
  String get exportAll => 'Ekspor semua kaset';

  @override
  String get exportAllDesc => 'Semuanya, ke dalam satu file arsip';

  @override
  String get exporting => 'Mengekspor…';

  @override
  String exportedTo(String path) {
    return 'Diekspor ke $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaset diekspor ke $path.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'Ekspor gagal: $error';
  }

  @override
  String get groupImport => 'Impor';

  @override
  String get importArchive => 'Impor arsip';

  @override
  String get importArchiveDesc => 'Tambahkan kaset dari ekspor sebelumnya';

  @override
  String get importing => 'Mengimpor…';

  @override
  String get importDialogTitle => 'IMPOR KASET?';

  @override
  String get importDialogBody =>
      'Kaset dalam arsip ditambahkan di samping kaset yang sudah ada — tidak ada yang dihapus atau diubah. Mengimpor kaset yang sudah ada di sini membuat salinan kedua, yang bisa Anda hapus sendiri. Memo yang belum punya transkrip atau ringkasan akan diproses setelah impor.';

  @override
  String get importAction => 'IMPOR';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos memo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: 'Berhasil mengimpor $cassettes kaset dengan $_temp0.',
    );
    return '$_temp1';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaset tidak dapat diimpor.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound => 'Tidak ada kaset ditemukan dalam arsip itu.';

  @override
  String importFailed(String error) {
    return 'Impor gagal: $error';
  }

  @override
  String exportNote(String date) {
    return 'Diekspor dari Diktafon pada $date.';
  }

  @override
  String get exportSummaryHeading => 'Ringkasan';

  @override
  String get exportNotTranscribed => '(belum ditranskripsi)';

  @override
  String get openSystemSettings => 'PENGATURAN';

  @override
  String get changeColor => 'Ubah warna';

  @override
  String get retranscribe => 'Transkripsi ulang';

  @override
  String get retranscribeTitle => 'TRANSKRIPSI ULANG KASET?';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count memo',
    );
    return '$_temp0 akan ditranskripsi ulang dengan model saat ini, dan ringkasan akan disusun ulang. Transkrip dan ringkasan yang ada akan diganti, termasuk koreksi manual. Proses ini bisa memakan waktu.';
  }

  @override
  String get retranscribeAction => 'TRANSKRIPSI ULANG';

  @override
  String get colorPickerTitle => 'WARNA KASET';

  @override
  String colorSwatch(int n) {
    return 'Warna $n';
  }

  @override
  String get copyTranscript => 'Salin transkripsi';

  @override
  String get editTranscript => 'Edit transkrip';

  @override
  String get editTranscriptTitle => 'EDIT TRANSKRIP';

  @override
  String get transcriptCopied => 'Transkripsi disalin.';

  @override
  String get deleteMemo => 'Hapus memo';

  @override
  String get memoActions => 'Tindakan memo';

  @override
  String notifDownloading(String label) {
    return 'Mengunduh $label';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label terpasang';
  }

  @override
  String get notifRecording => 'Sedang merekam';

  @override
  String get notifRecordingChannel => 'Perekaman';
}
