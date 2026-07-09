/// Android-only OS glue behind the `diktafon/system` channel (see
/// MainActivity.kt): the settings escape hatch for a permanently denied
/// microphone permission, and the SAF "create document" hand-off that
/// `file_selector` lacks on Android.
library;

import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('diktafon/system');

/// Opens this app's details page in the system settings (Android; see
/// MainActivity.kt). Best-effort no-op elsewhere — desktop recorders don't
/// gate on a permission.
Future<void> openAppSystemSettings() async {
  if (!Platform.isAndroid) return;
  try {
    await _channel.invokeMethod<void>('openAppSettings');
  } on PlatformException {
    // The snackbar text still names the destination; nothing to add here.
  }
}

/// Offers the OS "create document" dialog and copies the finished file at
/// [sourcePath] into whatever the user picked (Drive, Files, …). Returns
/// false when the user backs out. Android-only: desktop saves through
/// `getSaveLocation` and never lands here.
Future<bool> saveDocumentAndroid({
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
