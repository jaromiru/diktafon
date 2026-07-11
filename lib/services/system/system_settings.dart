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
