// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get untitledCassette => 'Cassete sem título';

  @override
  String get rename => 'Renomear';

  @override
  String get delete => 'Excluir';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get save => 'SALVAR';

  @override
  String get deleteAction => 'EXCLUIR';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Voltar';

  @override
  String get settingsTooltip => 'Configurações';

  @override
  String get homeEmpty =>
      'Ainda não há cassetes.\nToque em + para começar uma fita nova.';

  @override
  String get newCassette => 'Nova cassete';

  @override
  String get renameCassetteTitle => 'RENOMEAR CASSETE';

  @override
  String get cassetteNameHint => 'Nome da cassete';

  @override
  String get deleteCassetteTitle => 'EXCLUIR CASSETE?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'suas $count notas',
      one: 'sua $count nota',
    );
    return '\"$label\" e $_temp0 serão excluídas. Isso não pode ser desfeito.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '$count nota',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'vazia · toque para abrir';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · escolhendo um nome…';
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
    return 'hoje $time';
  }

  @override
  String get yesterday => 'ontem';

  @override
  String get deleteCassette => 'Excluir cassete';

  @override
  String get blankTape =>
      'Uma fita em branco.\nAperte a tecla vermelha para gravar.';

  @override
  String get emptyTape => 'FITA VAZIA';

  @override
  String memoCounter(int n, int total) {
    return 'NOTA $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'GRAVANDO NOTA $n';
  }

  @override
  String get summaryPlaceholder =>
      'O resumo da cassete aparece quando as notas forem transcritas.';

  @override
  String get back15 => 'Voltar 15 segundos';

  @override
  String get forward15 => 'Avançar 15 segundos';

  @override
  String get play => 'Reproduzir';

  @override
  String get pause => 'Pausar';

  @override
  String get recordNewMemo => 'Gravar uma nova nota';

  @override
  String get stopRecording => 'Parar a gravação';

  @override
  String get micPermissionNeeded =>
      'É preciso permissão do microfone para gravar.';

  @override
  String get deleteMemoTitle => 'EXCLUIR NOTA?';

  @override
  String deleteMemoBody(int n) {
    return 'A nota $n será removida e a fita fecha o espaço. Isso não pode ser desfeito.';
  }

  @override
  String get timelineLabel => 'Linha do tempo da fita';

  @override
  String timelinePosition(String position, String total) {
    return '$position de $total';
  }

  @override
  String get noSpeech => '(sem fala)';

  @override
  String get transcriptionFailedRetry =>
      'a transcrição falhou — toque para tentar de novo (o áudio continua tocando)';

  @override
  String get queuedForTranscription => 'na fila para transcrição…';

  @override
  String get waitingForModel =>
      'aguardando o modelo de transcrição — baixe-o em Configurações';

  @override
  String memoDivider(int n, String date) {
    return 'Nota $n — $date';
  }

  @override
  String get summarizing => 'resumindo…';

  @override
  String get summaryFailedRetry =>
      'o resumo falhou — toque para tentar de novo';

  @override
  String get transcribing => 'transcrevendo…';

  @override
  String get settingsTitle => 'CONFIGURAÇÕES';

  @override
  String get groupLanguage => 'Idioma';

  @override
  String get transcriptionLanguage => 'Idioma da transcrição';

  @override
  String get autoDetectValue => 'Automático — definido pela sua primeira nota';

  @override
  String get autoDetectOption => 'Detecção automática (da primeira gravação)';

  @override
  String get transcriptionLanguageTitle => 'IDIOMA DA TRANSCRIÇÃO';

  @override
  String get groupPlayback => 'Reprodução';

  @override
  String get boundaryChime => 'Aviso entre notas';

  @override
  String get boundaryChimeDesc =>
      'Um toque suave quando a fita passa para a próxima nota. Desligado = totalmente contínuo.';

  @override
  String get groupIntelligence => 'Inteligência no dispositivo';

  @override
  String get transcriptionModel => 'Modelo de transcrição';

  @override
  String get summaryModel => 'Modelo de resumos';

  @override
  String get summariesRow => 'Resumos';

  @override
  String get summariesRowDesc =>
      'A essência de cada nota e de cada cassete, gerada localmente';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — instalado, toque para gerenciar';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — baixando $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — ainda não baixado · toque para configurar';
  }

  @override
  String get groupAppearance => 'Aparência';

  @override
  String get themeRow => 'Tema';

  @override
  String get themeTitle => 'TEMA';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get groupYourData => 'Seus dados';

  @override
  String get backupExport => 'Backup e exportação';

  @override
  String get backupExportDesc =>
      'Leve suas cassetes com você — áudio, transcrições e resumos';

  @override
  String get aboutPrivacy => 'Sobre e privacidade';

  @override
  String get aboutPrivacyDesc => 'O áudio nunca sai deste dispositivo';

  @override
  String get aboutTitle => 'SOBRE E PRIVACIDADE';

  @override
  String get aboutBody =>
      'O Diktafon escuta, escreve e resume aqui mesmo, no seu telefone.\n\nGravações, transcrições e resumos nunca saem do dispositivo. Não há conta, nem nuvem, nem análises. Os dados só saem por um backup ou exportação que você mesmo inicia.';

  @override
  String get modelPickerTranscriptionTitle => 'MODELO DE TRANSCRIÇÃO';

  @override
  String get modelPickerSummaryTitle => 'MODELO DE RESUMOS';

  @override
  String pickerInstalled(String size) {
    return 'instalado · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'baixando $pct %';
  }

  @override
  String pickerDownload(String size) {
    return 'baixar · $size';
  }

  @override
  String needsRam(int gb) {
    return 'precisa de ≥ $gb GB de RAM';
  }

  @override
  String storageNote(int mb) {
    return 'Roda somente neste dispositivo. Espaço usado pelos modelos: $mb MB.';
  }

  @override
  String get deleteModelTooltip => 'Excluir o arquivo do modelo';

  @override
  String modelReadyTranscribe(String label) {
    return '$label está pronto — transcrevendo as notas em espera.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label está pronto — resumindo as notas em espera.';
  }

  @override
  String downloadFailed(String label) {
    return 'O download de $label falhou — verifique sua conexão e tente novamente.';
  }

  @override
  String get firstRunWelcome => 'Bem-vindo ao Diktafon';

  @override
  String get firstRunIntro =>
      'Ele escuta, escreve e resume aqui mesmo, no seu telefone. Gravações, transcrições e resumos **nunca saem deste dispositivo**. Não há conta nem nuvem.';

  @override
  String get allowMicRow => 'Permitir o microfone';

  @override
  String get micTapToGrant => 'Toque para conceder acesso';

  @override
  String get rowMicrophone => 'Microfone';

  @override
  String get accessGranted => 'Acesso concedido';

  @override
  String get micDeniedRetry =>
      'Não concedido — toque para perguntar de novo, ou permita o microfone nas configurações do sistema';

  @override
  String get rowTranscription => 'Transcrição';

  @override
  String get rowSummaries => 'Resumos';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · pronto';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · baixando — $pct %';
  }

  @override
  String get provisionWaiting => 'aguardando o download…';

  @override
  String get provisionFailedRetry =>
      'o download falhou — toque para tentar de novo';

  @override
  String get downloadsFinishInBackground =>
      'Os downloads terminam em segundo plano.';

  @override
  String get startRecordingKey => 'COMEÇAR A GRAVAR';

  @override
  String get backupTitle => 'BACKUP E EXPORTAÇÃO';

  @override
  String get backupIntro =>
      'O backup do seu dispositivo cobre automaticamente a lista de cassetes, as transcrições e os resumos. O áudio é pesado — leve-o explicitamente: a exportação grava uma pasta com os arquivos de áudio, a transcrição e os resumos. O Diktafon não envia nada.';

  @override
  String get groupExport => 'Exportar';

  @override
  String get exportAll => 'Exportar todas as cassetes';

  @override
  String get exportAllDesc => 'Tudo, em uma pasta que você escolhe';

  @override
  String get exporting => 'Exportando…';

  @override
  String exportedTo(String path) {
    return 'Exportado para $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cassetes exportadas para $path.',
      one: '$count cassete exportada para $path.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'A exportação falhou: $error';
  }

  @override
  String get pickLocalFolder =>
      'Não dá para gravar diretamente nessa pasta — escolha uma pasta local.';

  @override
  String exportNote(String date) {
    return 'Exportado do Diktafon em $date.';
  }

  @override
  String get exportSummaryHeading => 'Resumo';

  @override
  String get exportNotTranscribed => '(não transcrito)';
}
