/// Mobile OS glue behind the `diktafon/system` channel (MainActivity.kt on
/// Android, AppDelegate.swift on iOS): the settings escape hatch for a
/// permanently denied microphone permission, and the "save a finished file
/// through the OS" hand-off that `file_selector` lacks on both platforms.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('diktafon/system');

/// Whether saving a file goes through [saveDocumentMobile] instead of a
/// `getSaveLocation` dialog (which file_selector implements on desktop only).
bool get useMobileSaveFlow => Platform.isAndroid || Platform.isIOS;

/// Opens this app's page in the system settings (Android app details / iOS
/// Settings pane) — both OSes can permanently deny the mic prompt. Best-effort
/// no-op elsewhere — desktop recorders don't gate on a permission.
Future<void> openAppSystemSettings() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  try {
    await _channel.invokeMethod<void>('openAppSettings');
  } on PlatformException {
    // The snackbar text still names the destination; nothing to add here.
  }
}

/// Marks [path] `NSURLIsExcludedFromBackupKey` so re-downloadable bulk (the
/// models dir) stays out of iCloud/device backups — App Review rejects apps
/// that back up regenerable data. The attribute rides the directory item, so
/// one call covers everything under it; re-applied every launch because
/// restores and file-system migrations can drop it. No-op off iOS: Android
/// handles this declaratively in its backup-rules XML (§7.1).
Future<void> excludeFromIosBackup(String path) async {
  if (!Platform.isIOS) return;
  try {
    await _channel.invokeMethod<void>('excludeFromBackup', {'path': path});
  } on PlatformException {
    // Best-effort: a failure here must never block startup.
  }
}

/// D13: pins a microphone-type foreground service under the live capture so
/// Android keeps delivering mic audio with the app backgrounded or the
/// screen off (without it the OS feeds silence). Returns true when the
/// service is up; false when Android rejected the start — the caller falls
/// back to finalizing on backgrounding. The strings become the persistent
/// notification (localized by the caller; a service can't reach gen-l10n):
/// [title]/[channelName] for the card itself, [stopLabel] for its STOP
/// action. Android-only by design: iOS covers this with the `audio`
/// background mode and desktop activities never pause.
Future<bool> startRecordingForegroundService({
  required String title,
  required String channelName,
  required String stopLabel,
}) async {
  if (!Platform.isAndroid) return false;
  try {
    final started = await _channel.invokeMethod<bool>('startRecordingService', {
      'title': title,
      'channelName': channelName,
      'stopLabel': stopLabel,
    });
    return started ?? false;
  } on PlatformException {
    return false;
  }
}

/// The recording notification's STOP action, delivered as a stream: each
/// event is one tap on the card while the app is backgrounded. The platform
/// side invokes `stopRecording` on the `diktafon/recording_events` channel.
/// One app-lifetime broadcast stream — a single handler serves every
/// capture, so taps can never get lost to a re-subscribe race.
Stream<void>? _recordingStops;
Stream<void> recordingStopRequests() {
  if (!Platform.isAndroid) return const Stream.empty();
  return _recordingStops ??= () {
    const channel = MethodChannel('diktafon/recording_events');
    final controller = StreamController<void>.broadcast();
    channel.setMethodCallHandler((call) async {
      if (call.method == 'stopRecording') controller.add(null);
      return null;
    });
    return controller.stream;
  }();
}

/// Tears the recording service (and its notification) down — call on every
/// path that ends a capture. Safe to call when nothing is running.
Future<void> stopRecordingForegroundService() async {
  if (!Platform.isAndroid) return;
  try {
    await _channel.invokeMethod<void>('stopRecordingService');
  } on PlatformException {
    // The service dies with the process at the latest; nothing to add.
  }
}

/// Model-import pick: SAF open-document streamed to a cache staging file
/// whose path is answered (see MainActivity's importModelDocument).
/// file_selector's Android openFile materializes the whole document in RAM
/// and OOM-kills the app on gigabyte models, so Android goes through this
/// instead. Null = cancelled / no picker. Other platforms use file_selector.
Future<String?> pickModelDocument() async {
  if (!Platform.isAndroid) return null;
  try {
    return await _channel.invokeMethod<String>('importModelDocument');
  } on PlatformException {
    return null;
  }
}

/// Model-import folder (Android only): one SAF tree grant, valid for the
/// calls made while the user's pick is being processed. Null = cancelled.
Future<String?> pickModelsFolder() async {
  if (!Platform.isAndroid) return null;
  try {
    return await _channel.invokeMethod<String>('pickModelsFolder');
  } on PlatformException {
    return null;
  }
}

/// One entry of the granted model folder: a SAF document id (for staging)
/// plus the metadata Dart filters candidates by.
class FolderModelEntry {
  const FolderModelEntry({required this.id, required this.name, required this.size});

  final String id;
  final String name;
  final int size;
}

/// Lists the granted folder's files (Android only; empty on failure — the
/// grant may have lapsed if the call arrives after the picker was closed).
Future<List<FolderModelEntry>> listFolderModels(String treeUri) async {
  if (!Platform.isAndroid) return const [];
  try {
    final rows = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'listFolderModels', {'tree': treeUri});
    return [
      for (final row in rows ?? const [])
        FolderModelEntry(
          id: row['documentId']! as String,
          name: row['name']! as String,
          size: row['size']! as int,
        ),
    ];
  } on PlatformException {
    return const [];
  }
}

/// Streams one folder document into the import staging file and answers its
/// path (Android only; null on failure — the caller reports the miss).
Future<String?> stageFolderModel(String treeUri, String documentId) async {
  if (!Platform.isAndroid) return null;
  try {
    return await _channel.invokeMethod<String>(
        'stageFolderModel', {'tree': treeUri, 'documentId': documentId});
  } on PlatformException {
    return null;
  }
}

/// Offers the OS "save document" dialog (SAF create-document on Android,
/// export document picker on iOS) and lands the finished file at [sourcePath]
/// wherever the user picked (Drive, Files, …). Returns false when the user
/// backs out. Mobile-only: desktop saves through `getSaveLocation` and never
/// lands here. iOS exports the staged file by name — [suggestedName] must be
/// its basename (true for the staging flow in backup_screen.dart).
Future<bool> saveDocumentMobile({
  required String sourcePath,
  required String suggestedName,
  String mimeType = 'application/zip',
}) async {
  final saved = await _channel.invokeMethod<bool>('saveDocument', {
    'source': sourcePath,
    'name': suggestedName,
    'mime': mimeType,
  });
  return saved ?? false;
}
