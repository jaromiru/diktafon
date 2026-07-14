// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get untitledCassette => 'Adsız kaset';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get delete => 'Sil';

  @override
  String get cancel => 'İPTAL';

  @override
  String get save => 'KAYDET';

  @override
  String get deleteAction => 'SİL';

  @override
  String get ok => 'TAMAM';

  @override
  String get back => 'Geri';

  @override
  String get settingsTooltip => 'Ayarlar';

  @override
  String get homeEmpty =>
      'Henüz kaset yok.\nYeni bir bant başlatmak için + tuşuna basın.';

  @override
  String get newCassette => 'Yeni kaset';

  @override
  String get renameCassetteTitle => 'KASETİ YENİDEN ADLANDIR';

  @override
  String get cassetteNameHint => 'Kaset adı';

  @override
  String get deleteCassetteTitle => 'KASET SİLİNSİN Mİ?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not',
      one: '1 not',
    );
    return '“$label” ve üzerindeki $_temp0 silinecek. Bu geri alınamaz.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not',
      one: '1 not',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'boş · açmak için dokunun';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · adını buluyor…';
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
    return 'bugün $time';
  }

  @override
  String get yesterday => 'dün';

  @override
  String get deleteCassette => 'Kaseti sil';

  @override
  String get blankTape => 'Boş bir bant.\nKaydetmek için kırmızı tuşa basın.';

  @override
  String get emptyTape => 'BOŞ BANT';

  @override
  String memoCounter(int n, int total) {
    return 'NOT $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'NOT $n KAYDEDİLİYOR';
  }

  @override
  String get summaryPlaceholder =>
      'Notlar yazıya dökülünce kaset özeti burada görünür.';

  @override
  String get back15 => '15 saniye geri';

  @override
  String get forward15 => '15 saniye ileri';

  @override
  String get play => 'Oynat';

  @override
  String get pause => 'Duraklat';

  @override
  String get recordNewMemo => 'Yeni not kaydet';

  @override
  String get stopRecording => 'Kaydı durdur';

  @override
  String get micPermissionNeeded => 'Kayıt için mikrofon izni gerekli.';

  @override
  String get recordingFailed =>
      'Kayıt başlatılamadı — mikrofon kullanımda olabilir.';

  @override
  String get playbackError =>
      'Oynatma başarısız oldu — ses dosyası eksik veya bozuk olabilir.';

  @override
  String missingAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu cihazda $count notun sesi eksik.',
      one: 'Bu cihazda 1 notun sesi eksik.',
    );
    return '$_temp0';
  }

  @override
  String get deleteMemoTitle => 'NOT SİLİNSİN Mİ?';

  @override
  String deleteMemoBody(int n) {
    return 'Not $n kaldırılacak ve bant aradaki boşluğu kapatacak. Bu geri alınamaz.';
  }

  @override
  String get timelineLabel => 'Bant zaman çizelgesi';

  @override
  String timelinePosition(String position, String total) {
    return '$position / $total';
  }

  @override
  String get noSpeech => '(konuşma yok)';

  @override
  String get transcriptionFailedRetry =>
      'yazıya dökülemedi — tekrar denemek için dokunun (ses çalmaya devam eder)';

  @override
  String get queuedForTranscription => 'yazıya dökülmek için sırada…';

  @override
  String get waitingForModel =>
      'yazıya dökme modeli bekleniyor — Ayarlar\'dan indirin';

  @override
  String memoDivider(int n, String date) {
    return 'Not $n — $date';
  }

  @override
  String get summarizing => 'özetleniyor…';

  @override
  String get summaryFailedRetry =>
      'özet oluşturulamadı — tekrar denemek için dokunun';

  @override
  String get transcribing => 'yazıya dökülüyor…';

  @override
  String get settingsTitle => 'AYARLAR';

  @override
  String get groupLanguage => 'Dil';

  @override
  String get transcriptionLanguage => 'Yazıya dökme dili';

  @override
  String get autoDetectValue => 'Otomatik algıla — her not kendi dilini korur';

  @override
  String get autoDetectOption => 'Otomatik algıla (not başına)';

  @override
  String get transcriptionLanguageTitle => 'YAZIYA DÖKME DİLİ';

  @override
  String get groupPlayback => 'Oynatma';

  @override
  String get boundaryChime => 'Geçiş sinyali';

  @override
  String get boundaryChimeDesc =>
      'Bant bir sonraki nota geçerken duyulan yumuşak bir işaret. Kapalı = tamamen kesintisiz.';

  @override
  String get groupIntelligence => 'Cihaz üzerinde yapay zekâ';

  @override
  String get transcriptionModel => 'Yazıya dökme modeli';

  @override
  String get summaryModel => 'Özet modeli';

  @override
  String get summariesOffOption => 'Özet yok';

  @override
  String get summariesOffDesc =>
      'Notlar yalnızca yazıya dökülür — özet, kaset genel özeti ve başlık önerisi olmaz.';

  @override
  String get whisperSmallDesc => 'Önerilen — en iyi boyut/kalite dengesi.';

  @override
  String get whisperSmallDescCapable =>
      'Daha hafif ve hızlı — özellikle gürültülü kayıtlarda daha az doğru.';

  @override
  String get whisperLargeDesc =>
      'Daha yüksek doğruluk; güçlü bir cihaz gerektirir (yazıya dökme sırasında ~2,5 GB RAM).';

  @override
  String get whisperLargeDescCapable =>
      'Önerilen — özellikle gürültüde çok daha doğru (yazıya dökme sırasında ~2,5 GB RAM).';

  @override
  String get llmDefaultDesc => 'Önerilen — derli toplu çok dilli özetler.';

  @override
  String get llm4bDesc =>
      'Daha kaliteli özetler ve başlıklar; güçlü bir cihaz gerektirir (özetleme sırasında ~3 GB RAM).';

  @override
  String get summariesOffValue => 'Özet yok · kurmak için dokunun';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — yüklü, yönetmek için dokunun';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — indiriliyor %$pct';
  }

  @override
  String modelPaused(String label, int pct) {
    return '$label — indirme duraklatıldı (%$pct)';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — henüz indirilmedi · kurmak için dokunun';
  }

  @override
  String get groupAppearance => 'Görünüm';

  @override
  String get themeRow => 'Tema';

  @override
  String get themeTitle => 'TEMA';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get groupYourData => 'Verileriniz';

  @override
  String get backupExport => 'Dışa ve içe aktarma';

  @override
  String get backupExportDesc =>
      'Kasetlerinizi yanınıza alın — ses, transkriptler ve özetler — ya da geri getirin';

  @override
  String get aboutPrivacy => 'Hakkında ve gizlilik';

  @override
  String get aboutPrivacyDesc => 'Ses asla bu cihazdan çıkmaz';

  @override
  String get aboutTitle => 'HAKKINDA VE GİZLİLİK';

  @override
  String get aboutBody =>
      'Diktafon doğrudan telefonunuzda dinler, yazar ve özetler.\n\nKayıtlar, transkriptler ve özetler cihazdan asla çıkmaz. Hesap yok, bulut yok, analitik yok. Veriler yalnızca sizin başlattığınız bir yedekleme veya dışa aktarmayla cihazdan ayrılır.';

  @override
  String get aboutOpenSource => 'Diktafon ücretsiz ve açık kaynaklıdır:';

  @override
  String get aboutPrivacyPolicy => 'Gizlilik politikası';

  @override
  String get modelPickerTranscriptionTitle => 'YAZIYA DÖKME MODELİ';

  @override
  String get modelPickerSummaryTitle => 'ÖZET MODELİ';

  @override
  String pickerInstalled(String size) {
    return 'yüklü · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'indiriliyor %$pct — duraklatmak için dokunun';
  }

  @override
  String pickerPaused(int pct) {
    return 'duraklatıldı %$pct — sürdürmek için dokunun';
  }

  @override
  String pickerDownload(String size) {
    return 'indir · $size';
  }

  @override
  String needsRam(int gb) {
    return '≥ $gb GB RAM gerektirir';
  }

  @override
  String storageNote(int mb) {
    return 'Yalnızca bu cihazda çalışır. Modellerin kapladığı alan: $mb MB.';
  }

  @override
  String get deleteModelTooltip => 'Model dosyasını sil';

  @override
  String modelReadyTranscribe(String label) {
    return '$label hazır — bekleyen notlar yazıya dökülüyor.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label hazır — bekleyen notlar özetleniyor.';
  }

  @override
  String downloadFailed(String label) {
    return '$label indirilemedi — bağlantınızı kontrol edip tekrar deneyin.';
  }

  @override
  String get firstRunWelcome => 'Diktafon\'a hoş geldiniz';

  @override
  String get firstRunIntro =>
      'Doğrudan telefonunuzda dinler, yazar ve özetler. Kayıtlar, transkriptler ve özetler **bu cihazdan asla çıkmaz**. Hesap yok, bulut yok.';

  @override
  String get firstRunSetupHeader => 'İlk kurulum';

  @override
  String get allowMicRow => 'Mikrofona izin ver';

  @override
  String get micTapToGrant => 'İzin vermek için dokunun';

  @override
  String get rowMicrophone => 'Mikrofon';

  @override
  String get accessGranted => 'İzin verildi';

  @override
  String get micDeniedRetry =>
      'İzin verilmedi — tekrar sormak için dokunun ya da mikrofona sistem ayarlarından izin verin';

  @override
  String get rowTranscription => 'Yazıya dökme';

  @override
  String get rowSummaries => 'Özetler';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · hazır';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · indiriliyor — %$pct';
  }

  @override
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · duraklatıldı — %$pct';
  }

  @override
  String get provisionChoose => 'indirilecek modeli seçmek için dokunun';

  @override
  String get downloadsFinishInBackground =>
      'İndirmeler arka planda tamamlanır.';

  @override
  String get startRecordingKey => 'KAYDA BAŞLA';

  @override
  String get backupTitle => 'DIŞA VE İÇE AKTARMA';

  @override
  String get backupIntro =>
      'Cihazınızın kendi yedeği kaset listesini, transkriptleri ve özetleri otomatik olarak kapsar. Ses kayıtları büyüktür — onları açıkça yanınıza alın: dışa aktarma, bir kasetin sesini, transkriptlerini ve özetlerini tek bir .zip arşivine paketler; arşivi içe aktarmak onları geri getirir. Diktafon hiçbir şeyi hiçbir yere yüklemez.';

  @override
  String get groupExport => 'Dışa aktarma';

  @override
  String get exportAll => 'Tüm kasetleri dışa aktar';

  @override
  String get exportAllDesc => 'Her şey, tek bir arşiv dosyasına';

  @override
  String get exporting => 'Dışa aktarılıyor…';

  @override
  String exportedTo(String path) {
    return '$path konumuna aktarıldı.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaset $path konumuna aktarıldı.',
      one: '1 kaset $path konumuna aktarıldı.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'Dışa aktarma başarısız: $error';
  }

  @override
  String get groupImport => 'İçe aktarma';

  @override
  String get importArchive => 'Arşivi içe aktar';

  @override
  String get importArchiveDesc => 'Önceki bir dışa aktarmadan kasetleri ekler';

  @override
  String get importing => 'İçe aktarılıyor…';

  @override
  String get importDialogTitle => 'KASETLER İÇE AKTARILSIN MI?';

  @override
  String get importDialogBody =>
      'Arşivdeki kasetler mevcut olanların yanına eklenir — hiçbir şey silinmez veya değiştirilmez. Zaten burada olan bir kaseti içe aktarmak ikinci bir kopya oluşturur; onu elle silebilirsiniz. Transkripti veya özeti eksik notlar içe aktarmadan sonra işlenir.';

  @override
  String get importAction => 'İÇE AKTAR';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos not',
      one: '1 not',
    );
    String _temp1 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos not',
      one: '1 not',
    );
    String _temp2 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: '$cassettes kaset ve $_temp0 içe aktarıldı.',
      one: '1 kaset ve $_temp1 içe aktarıldı.',
    );
    return '$_temp2';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaset içe aktarılamadı.',
      one: '1 kaset içe aktarılamadı.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound => 'Bu arşivde kaset bulunamadı.';

  @override
  String importFailed(String error) {
    return 'İçe aktarma başarısız: $error';
  }

  @override
  String exportNote(String date) {
    return '$date tarihinde Diktafon\'dan dışa aktarıldı.';
  }

  @override
  String get exportSummaryHeading => 'Özet';

  @override
  String get exportNotTranscribed => '(yazıya dökülmedi)';

  @override
  String get openSystemSettings => 'AYARLAR';

  @override
  String get changeColor => 'Rengi değiştir';

  @override
  String get retranscribe => 'Yeniden yazıya dök';

  @override
  String get retranscribeTitle => 'KASET YENİDEN YAZIYA DÖKÜLSÜN MÜ?';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notun tümü',
      one: 'Not',
    );
    return '$_temp0 güncel modellerle yeniden yazıya dökülecek ve özet yeniden oluşturulacak. Mevcut transkriptler ve özetler değiştirilir. Bu biraz sürebilir.';
  }

  @override
  String get retranscribeAction => 'YENİDEN DÖK';

  @override
  String get colorPickerTitle => 'KASET RENGİ';

  @override
  String colorSwatch(int n) {
    return 'Renk $n';
  }

  @override
  String get copyTranscript => 'Transkripti kopyala';

  @override
  String get transcriptCopied => 'Transkript kopyalandı.';

  @override
  String get deleteMemo => 'Notu sil';

  @override
  String get memoActions => 'Not işlemleri';

  @override
  String notifDownloading(String label) {
    return '$label indiriliyor';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label yüklendi';
  }
}
