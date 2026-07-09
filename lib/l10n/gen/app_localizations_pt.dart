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
  String get autoDetectValue =>
      'Automático — cada nota mantém o seu próprio idioma';

  @override
  String get autoDetectOption => 'Detecção automática (por nota)';

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
  String modelPaused(String label, int pct) {
    return '$label — download pausado em $pct %';
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
  String get backupExport => 'Exportar e importar';

  @override
  String get backupExportDesc =>
      'Leve suas cassetes com você — áudio, transcrições e resumos — ou traga-as de volta';

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
  String get aboutOpenSource => 'O Diktafon é gratuito e de código aberto:';

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
    return 'baixando $pct % — toque para pausar';
  }

  @override
  String pickerPaused(int pct) {
    return 'pausado em $pct % — toque para retomar';
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
  String get firstRunSetupHeader => 'Configuração inicial';

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
  String provisionPaused(String label, String size, int pct) {
    return '$label · $size · pausado — $pct %';
  }

  @override
  String get provisionChoose => 'toque para escolher um modelo para baixar';

  @override
  String get downloadsFinishInBackground =>
      'Os downloads terminam em segundo plano.';

  @override
  String get startRecordingKey => 'COMEÇAR A GRAVAR';

  @override
  String get backupTitle => 'EXPORTAR E IMPORTAR';

  @override
  String get backupIntro =>
      'O backup do seu dispositivo cobre automaticamente a lista de cassetes, as transcrições e os resumos. O áudio é pesado — leve-o explicitamente: a exportação empacota o áudio, as transcrições e os resumos de uma cassete em um único arquivo .zip, e a importação os traz de volta. O Diktafon não envia nada.';

  @override
  String get groupExport => 'Exportar';

  @override
  String get exportAll => 'Exportar todas as cassetes';

  @override
  String get exportAllDesc => 'Tudo, em um único arquivo';

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
  String get groupImport => 'Importar';

  @override
  String get importArchive => 'Importar um arquivo';

  @override
  String get importArchiveDesc =>
      'Adiciona cassetes de uma exportação anterior';

  @override
  String get importing => 'Importando…';

  @override
  String get importDialogTitle => 'IMPORTAR CASSETES?';

  @override
  String get importDialogBody =>
      'As cassetes do arquivo são adicionadas ao lado das que você já tem — nada é apagado nem alterado. Importar uma cassete que já está aqui cria uma segunda cópia, que você pode apagar manualmente. Notas sem transcrição ou resumo são processadas depois da importação.';

  @override
  String get importAction => 'IMPORTAR';

  @override
  String importedResult(int cassettes, int memos) {
    String _temp0 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos notas',
      one: '$memos nota',
    );
    String _temp1 = intl.Intl.pluralLogic(
      memos,
      locale: localeName,
      other: '$memos notas',
      one: '$memos nota',
    );
    String _temp2 = intl.Intl.pluralLogic(
      cassettes,
      locale: localeName,
      other: 'Importadas $cassettes cassetes com $_temp0.',
      one: 'Importada 1 cassete com $_temp1.',
    );
    return '$_temp2';
  }

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Não foi possível importar $count cassetes.',
      one: 'Não foi possível importar 1 cassete.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingFound => 'Nenhuma cassete encontrada nesse arquivo.';

  @override
  String importFailed(String error) {
    return 'A importação falhou: $error';
  }

  @override
  String exportNote(String date) {
    return 'Exportado do Diktafon em $date.';
  }

  @override
  String get exportSummaryHeading => 'Resumo';

  @override
  String get exportNotTranscribed => '(não transcrito)';

  @override
  String get openSystemSettings => 'CONFIGURAÇÕES';

  @override
  String get changeColor => 'Mudar a cor';

  @override
  String get retranscribe => 'Transcrever de novo';

  @override
  String get retranscribeTitle => 'TRANSCREVER A CASSETE DE NOVO?';

  @override
  String retranscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'As $count notas serão transcritas',
      one: 'A nota será transcrita',
    );
    return '$_temp0 de novo com os modelos atuais e o resumo será refeito. As transcrições e os resumos existentes serão substituídos. Isso pode levar um tempo.';
  }

  @override
  String get retranscribeAction => 'TRANSCREVER';

  @override
  String get colorPickerTitle => 'COR DA CASSETE';

  @override
  String colorSwatch(int n) {
    return 'Cor $n';
  }

  @override
  String get copyTranscript => 'Copiar transcrição';

  @override
  String get transcriptCopied => 'Transcrição copiada.';

  @override
  String get deleteMemo => 'Excluir nota';

  @override
  String get memoActions => 'Ações da nota';

  @override
  String get cleanupRow => 'Limpeza de transcrições';

  @override
  String get cleanupRowDesc =>
      'O modelo de resumos corrige as transcrições — erros de grafia e de reconhecimento';

  @override
  String notifDownloading(String label) {
    return 'Baixando $label';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label instalado';
  }
}
