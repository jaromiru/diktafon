/// Surfaces model downloads in the OS notification area (like a store app
/// install): a progress notification per tier on the wire, a quiet "done"
/// notice when it lands, gone again on cancel/failure (Settings and
/// first-run surface failures in-app). Pure orchestration over
/// [ModelManager.changes] behind [DownloadNotificationSink] — the plugin
/// lives in `local_notifications_sink.dart`, tests record into a fake
/// (chime-seam style).
library;

import 'dart:async';

import '../providers/model_manager.dart';
import '../providers/transcription_provider.dart' show ModelStatus;

/// Where the notifications land; implemented over flutter_local_notifications
/// in main(), by a recording fake in tests.
abstract interface class DownloadNotificationSink {
  /// Shows or updates (same [id]) the ongoing progress notification.
  Future<void> showProgress(int id, String title, int percent);

  /// Replaces [id] with a dismissible "installed" notice.
  Future<void> showDone(int id, String title);

  /// Removes [id] — the download was cancelled or failed.
  Future<void> cancel(int id);
}

/// Notification copy, resolved once at startup (no BuildContext out here).
class DownloadNotificationTexts {
  const DownloadNotificationTexts({
    required this.downloading,
    required this.installed,
  });

  final String Function(String modelLabel) downloading;
  final String Function(String modelLabel) installed;
}

class ModelDownloadNotifier {
  ModelDownloadNotifier(this._sink, this._texts);

  final DownloadNotificationSink _sink;
  final DownloadNotificationTexts _texts;
  final List<StreamSubscription<void>> _subs = [];

  /// tier → last shown percent; an entry exists only while the tier's
  /// progress notification is up. Gates the chunk-level [ModelManager]
  /// events down to at most one notification update per percent.
  final Map<String, int> _shownPercent = {};

  /// Sink calls are chained so updates can't overtake each other; a broken
  /// notification daemon must never take the download down with it.
  Future<void> _chain = Future.value();
  void _enqueue(Future<void> Function() op) {
    _chain = _chain.then((_) => op()).catchError((_) {});
  }

  /// Mirrors [manager]'s downloads; notification ids are `idBase + catalog
  /// index`, so give each engine its own base.
  void attach(ModelManager<ModelSpec> manager, {required int idBase}) {
    final initial = manager.snapshot();
    final last = <String, ModelStatus>{
      for (final state in initial) state.model.tier: state.status,
    };
    // A process killed mid-download leaves its ongoing progress notification
    // stranded in the shade (it can't even be swiped away) — clear every
    // tier that isn't actually on the wire right now.
    for (var i = 0; i < initial.length; i++) {
      if (initial[i].status != ModelStatus.downloading) {
        final id = idBase + i;
        _enqueue(() => _sink.cancel(id));
      }
    }
    _subs.add(manager.changes.listen((_) {
      final snapshot = manager.snapshot();
      for (var i = 0; i < snapshot.length; i++) {
        final state = snapshot[i];
        final tier = state.model.tier;
        final id = idBase + i;
        switch (state.status) {
          case ModelStatus.downloading:
            final percent = (state.progress * 100).floor().clamp(0, 100);
            if (_shownPercent[tier] != percent) {
              _shownPercent[tier] = percent;
              _enqueue(() => _sink.showProgress(
                  id, _texts.downloading(state.model.label), percent));
            }
          case ModelStatus.ready:
            if (last[tier] == ModelStatus.downloading) {
              _shownPercent.remove(tier);
              _enqueue(() =>
                  _sink.showDone(id, _texts.installed(state.model.label)));
            }
          case ModelStatus.notInstalled:
            if (last[tier] == ModelStatus.downloading) {
              _shownPercent.remove(tier);
              _enqueue(() => _sink.cancel(id));
            }
        }
        last[tier] = state.status;
      }
    }));
  }

  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
  }
}
