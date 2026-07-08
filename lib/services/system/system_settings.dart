/// Escape hatch for a permanently denied microphone permission: Android
/// stops showing the OS prompt after repeated denials, so the only way back
/// is the app's page in the system settings.
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
