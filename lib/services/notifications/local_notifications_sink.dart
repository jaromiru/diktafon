/// The flutter_local_notifications implementation of
/// [DownloadNotificationSink]. Android is the point (a low-importance
/// progress channel, like a store install); Linux gets a plain updating
/// bubble with the percent in the body. Everything is best-effort — a
/// missing daemon or denied permission must never disturb the download.
library;

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'download_notifier.dart';

class LocalNotificationsSink implements DownloadNotificationSink {
  LocalNotificationsSink._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _permissionRequested = false;

  /// Null on platforms without a wired-up notification backend (or when the
  /// plugin fails to initialize) — callers then skip the notifier entirely.
  static Future<LocalNotificationsSink?> init() async {
    if (!Platform.isAndroid && !Platform.isLinux) return null;
    final plugin = FlutterLocalNotificationsPlugin();
    try {
      final ok = await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        ),
      );
      if (ok == false) return null;
    } catch (_) {
      return null;
    }
    return LocalNotificationsSink._(plugin);
  }

  /// Android 13+ gates notifications behind a runtime permission; asked
  /// lazily, the first time a download actually has something to show. A
  /// denial is final for this run — the plugin just no-ops on show().
  Future<void> _ensurePermission() async {
    if (_permissionRequested) return;
    _permissionRequested = true;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static AndroidNotificationDetails _android({int? progress}) =>
      AndroidNotificationDetails(
        'model_downloads',
        'Model downloads',
        channelDescription: 'Progress of on-device model downloads',
        importance: Importance.low,
        priority: Priority.low,
        onlyAlertOnce: true,
        ongoing: progress != null,
        autoCancel: progress == null,
        showProgress: progress != null,
        maxProgress: 100,
        progress: progress ?? 0,
      );

  static const _linux = LinuxNotificationDetails(suppressSound: true);

  @override
  Future<void> showProgress(int id, String title, int percent) async {
    await _ensurePermission();
    await _plugin.show(
      id: id,
      title: title,
      body: '$percent %',
      notificationDetails: NotificationDetails(
          android: _android(progress: percent), linux: _linux),
    );
  }

  @override
  Future<void> showDone(int id, String title) async {
    // Cancel first: updating an `ongoing` progress notification in place can
    // leave it stuck non-dismissible on some Android versions — replace it
    // outright with the plain, swipeable "installed" notice.
    await _plugin.cancel(id: id);
    await _plugin.show(
      id: id,
      title: title,
      notificationDetails:
          NotificationDetails(android: _android(), linux: _linux),
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
