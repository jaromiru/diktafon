/// Mobile OS glue behind the `diktafon/system` channel (MainActivity.kt on
/// Android, AppDelegate.swift on iOS): the settings escape hatch for a
/// permanently denied microphone permission, and the "save a finished file
/// through the OS" hand-off that `file_selector` lacks on both platforms.
library;

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
/// notification (localized by the caller; a service can't reach gen-l10n).
/// Android-only by design: iOS covers this with the `audio` background mode
/// and desktop activities never pause.
Future<bool> startRecordingForegroundService({
  required String title,
  required String channelName,
}) async {
  if (!Platform.isAndroid) return false;
  try {
    final started = await _channel.invokeMethod<bool>('startRecordingService', {
      'title': title,
      'channelName': channelName,
    });
    return started ?? false;
  } on PlatformException {
    return false;
  }
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
