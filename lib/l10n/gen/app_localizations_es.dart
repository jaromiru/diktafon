// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get untitledCassette => 'Casete sin título';

  @override
  String get rename => 'Renombrar';

  @override
  String get delete => 'Eliminar';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get save => 'GUARDAR';

  @override
  String get deleteAction => 'ELIMINAR';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Atrás';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get homeEmpty =>
      'Aún no hay casetes.\nPulsa + para empezar una cinta nueva.';

  @override
  String get newCassette => 'Nuevo casete';

  @override
  String get renameCassetteTitle => 'RENOMBRAR CASETE';

  @override
  String get cassetteNameHint => 'Nombre del casete';

  @override
  String get deleteCassetteTitle => '¿ELIMINAR CASETE?';

  @override
  String deleteCassetteBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sus $count notas',
      one: 'su 1 nota',
    );
    return '«$label» y $_temp0 se eliminarán. Esto no se puede deshacer.';
  }

  @override
  String memoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String get cardEmptyMeta => 'vacío · pulsa para abrir';

  @override
  String cardMetaNaming(String memos) {
    return '$memos · buscando nombre…';
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
    return 'hoy $time';
  }

  @override
  String get yesterday => 'ayer';

  @override
  String get deleteCassette => 'Eliminar casete';

  @override
  String get blankTape =>
      'Una cinta en blanco.\nPulsa la tecla roja para grabar.';

  @override
  String get emptyTape => 'CINTA VACÍA';

  @override
  String memoCounter(int n, int total) {
    return 'NOTA $n / $total';
  }

  @override
  String recordingMemo(int n) {
    return 'GRABANDO NOTA $n';
  }

  @override
  String get summaryPlaceholder =>
      'El resumen del casete aparece cuando las notas estén transcritas.';

  @override
  String get back15 => 'Retroceder 15 segundos';

  @override
  String get forward15 => 'Avanzar 15 segundos';

  @override
  String get play => 'Reproducir';

  @override
  String get pause => 'Pausa';

  @override
  String get recordNewMemo => 'Grabar una nota nueva';

  @override
  String get stopRecording => 'Detener la grabación';

  @override
  String get micPermissionNeeded =>
      'Para grabar se necesita permiso del micrófono.';

  @override
  String get deleteMemoTitle => '¿ELIMINAR NOTA?';

  @override
  String deleteMemoBody(int n) {
    return 'La nota $n se eliminará y la cinta cerrará el hueco. Esto no se puede deshacer.';
  }

  @override
  String get timelineLabel => 'Línea de tiempo de la cinta';

  @override
  String timelinePosition(String position, String total) {
    return '$position de $total';
  }

  @override
  String get noSpeech => '(sin voz)';

  @override
  String get transcriptionFailedRetry =>
      'la transcripción falló — toca para reintentar (el audio sigue sonando)';

  @override
  String get queuedForTranscription => 'en cola para transcribir…';

  @override
  String get waitingForModel =>
      'esperando el modelo de transcripción — descárgalo en Ajustes';

  @override
  String memoDivider(int n, String date) {
    return 'Nota $n — $date';
  }

  @override
  String get summarizing => 'resumiendo…';

  @override
  String get summaryFailedRetry => 'el resumen falló — toca para reintentar';

  @override
  String get transcribing => 'transcribiendo…';

  @override
  String get settingsTitle => 'AJUSTES';

  @override
  String get groupLanguage => 'Idioma';

  @override
  String get transcriptionLanguage => 'Idioma de transcripción';

  @override
  String get autoDetectValue =>
      'Automático — cada nota conserva su propio idioma';

  @override
  String get autoDetectOption => 'Detección automática (por nota)';

  @override
  String get transcriptionLanguageTitle => 'IDIOMA DE TRANSCRIPCIÓN';

  @override
  String get groupPlayback => 'Reproducción';

  @override
  String get boundaryChime => 'Aviso entre notas';

  @override
  String get boundaryChimeDesc =>
      'Una señal suave cuando la cinta pasa a la siguiente nota. Apagado = totalmente continuo.';

  @override
  String get groupIntelligence => 'Inteligencia en el dispositivo';

  @override
  String get transcriptionModel => 'Modelo de transcripción';

  @override
  String get summaryModel => 'Modelo de resúmenes';

  @override
  String get summariesRow => 'Resúmenes';

  @override
  String get summariesRowDesc =>
      'La esencia de cada nota y de cada casete, generada localmente';

  @override
  String modelInstalled(String label, String size) {
    return '$label · $size — instalado, toca para gestionar';
  }

  @override
  String modelDownloading(String label, int pct) {
    return '$label — descargando $pct %';
  }

  @override
  String modelNotDownloaded(String label) {
    return '$label — aún sin descargar · toca para configurar';
  }

  @override
  String get groupAppearance => 'Apariencia';

  @override
  String get themeRow => 'Tema';

  @override
  String get themeTitle => 'TEMA';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get groupYourData => 'Tus datos';

  @override
  String get backupExport => 'Exportar datos';

  @override
  String get backupExportDesc =>
      'Llévate tus casetes — audio, transcripciones y resúmenes';

  @override
  String get aboutPrivacy => 'Acerca de y privacidad';

  @override
  String get aboutPrivacyDesc => 'El audio nunca sale de este dispositivo';

  @override
  String get aboutTitle => 'ACERCA DE Y PRIVACIDAD';

  @override
  String get aboutBody =>
      'Diktafon escucha, escribe y resume aquí mismo, en tu teléfono.\n\nLas grabaciones, transcripciones y resúmenes nunca salen del dispositivo. No hay cuenta, ni nube, ni analíticas. Los datos solo salen mediante una copia o exportación que inicias tú.';

  @override
  String get modelPickerTranscriptionTitle => 'MODELO DE TRANSCRIPCIÓN';

  @override
  String get modelPickerSummaryTitle => 'MODELO DE RESÚMENES';

  @override
  String pickerInstalled(String size) {
    return 'instalado · $size';
  }

  @override
  String pickerDownloading(int pct) {
    return 'descargando $pct %';
  }

  @override
  String pickerDownload(String size) {
    return 'descargar · $size';
  }

  @override
  String needsRam(int gb) {
    return 'necesita ≥ $gb GB de RAM';
  }

  @override
  String storageNote(int mb) {
    return 'Funciona solo en este dispositivo. Espacio ocupado por los modelos: $mb MB.';
  }

  @override
  String get deleteModelTooltip => 'Eliminar el archivo del modelo';

  @override
  String modelReadyTranscribe(String label) {
    return '$label está listo — transcribiendo las notas en espera.';
  }

  @override
  String modelReadySummarize(String label) {
    return '$label está listo — resumiendo las notas en espera.';
  }

  @override
  String downloadFailed(String label) {
    return 'La descarga de $label falló — comprueba tu conexión e inténtalo de nuevo.';
  }

  @override
  String get firstRunWelcome => 'Bienvenido a Diktafon';

  @override
  String get firstRunIntro =>
      'Escucha, escribe y resume aquí mismo, en tu teléfono. Las grabaciones, transcripciones y resúmenes **nunca salen de este dispositivo**. No hay cuenta ni nube.';

  @override
  String get allowMicRow => 'Permitir el micrófono';

  @override
  String get micTapToGrant => 'Toca para conceder acceso';

  @override
  String get rowMicrophone => 'Micrófono';

  @override
  String get accessGranted => 'Acceso concedido';

  @override
  String get micDeniedRetry =>
      'Sin conceder — toca para preguntar de nuevo, o permite el micrófono en los ajustes del sistema';

  @override
  String get rowTranscription => 'Transcripción';

  @override
  String get rowSummaries => 'Resúmenes';

  @override
  String provisionReady(String label, String size) {
    return '$label · $size · listo';
  }

  @override
  String provisionDownloading(String label, String size, int pct) {
    return '$label · $size · descargando — $pct %';
  }

  @override
  String get provisionChoose => 'toca para elegir un modelo para descargar';

  @override
  String get downloadsFinishInBackground =>
      'Las descargas terminan en segundo plano.';

  @override
  String get startRecordingKey => 'EMPEZAR A GRABAR';

  @override
  String get backupTitle => 'EXPORTAR DATOS';

  @override
  String get backupIntro =>
      'La copia de seguridad de tu dispositivo cubre automáticamente la lista de casetes, las transcripciones y los resúmenes. El audio ocupa mucho — llévatelo de forma explícita: la exportación escribe una carpeta con los archivos de audio, la transcripción y los resúmenes. Diktafon no sube nada.';

  @override
  String get groupExport => 'Exportar';

  @override
  String get exportAll => 'Exportar todos los casetes';

  @override
  String get exportAllDesc => 'Todo, en una carpeta que tú eliges';

  @override
  String get exporting => 'Exportando…';

  @override
  String exportedTo(String path) {
    return 'Exportado a $path.';
  }

  @override
  String exportedAllTo(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count casetes exportados a $path.',
      one: '1 casete exportado a $path.',
    );
    return '$_temp0';
  }

  @override
  String exportFailed(String error) {
    return 'La exportación falló: $error';
  }

  @override
  String get pickLocalFolder =>
      'No se puede escribir directamente en esa carpeta — elige una carpeta local.';

  @override
  String exportNote(String date) {
    return 'Exportado desde Diktafon el $date.';
  }

  @override
  String get exportSummaryHeading => 'Resumen';

  @override
  String get exportNotTranscribed => '(sin transcribir)';

  @override
  String get openSystemSettings => 'AJUSTES';

  @override
  String get changeColor => 'Cambiar color';

  @override
  String get colorPickerTitle => 'COLOR DEL CASETE';

  @override
  String colorSwatch(int n) {
    return 'Color $n';
  }

  @override
  String get copyTranscript => 'Copiar transcripción';

  @override
  String get transcriptCopied => 'Transcripción copiada.';

  @override
  String get deleteMemo => 'Eliminar nota';

  @override
  String get memoActions => 'Acciones de la nota';

  @override
  String get cleanupRow => 'Limpieza de transcripciones';

  @override
  String get cleanupRowDesc =>
      'El modelo de resúmenes pule las transcripciones — errores de ortografía y de reconocimiento';

  @override
  String notifDownloading(String label) {
    return 'Descargando $label';
  }

  @override
  String notifModelInstalled(String label) {
    return '$label instalado';
  }
}
