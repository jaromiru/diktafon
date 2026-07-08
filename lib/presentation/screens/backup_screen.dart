import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../data/repositories/cassette_repository.dart';
import '../../l10n/l10n.dart';
import '../../services/export/cassette_exporter.dart';
import '../theme/tape_colors.dart';
import '../widgets/settings_rows.dart';

/// Backup & export (§8): OS backup covers the metadata automatically; large
/// audio is protected by an explicit, user-initiated export to a folder of
/// the user's choosing — one cassette or the whole shelf.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    final l10n = context.l10n;
    final overviews = ref.watch(cassetteOverviewsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          tooltip: l10n.back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n.backupTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Text(
              l10n.backupIntro,
              style: TextStyle(fontSize: 11, height: 1.55, color: tape.ink2),
            ),
          ),
          SettingsGroup(title: l10n.groupExport, rows: [
            SettingsRow(
              title: l10n.exportAll,
              value: _exporting ? l10n.exporting : l10n.exportAllDesc,
              onTap: _exporting || overviews.isEmpty
                  ? null
                  : () => _export(overviews),
            ),
            for (final overview in overviews)
              SettingsRow(
                title: overview.cassette.label ?? l10n.untitledCassette,
                value: l10n.memoCount(overview.memoCount),
                onTap: _exporting ? null : () => _export([overview]),
              ),
          ]),
        ],
      ),
    );
  }

  Future<void> _export(List<CassetteOverview> selection) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final labels = _exportLabels(context);
    final path = await getDirectoryPath();
    if (path == null || !mounted) return; // user cancelled the picker

    final target = Directory(path);
    if (!await target.exists()) {
      // e.g. a SAF content-URI on Android — not a filesystem path (§8's
      // Android export lands with device testing).
      messenger.showSnackBar(SnackBar(content: Text(l10n.pickLocalFolder)));
      return;
    }

    setState(() => _exporting = true);
    try {
      final memoRepo = ref.read(memoRepositoryProvider);
      final exporter = CassetteExporter(labels: labels);
      for (final overview in selection) {
        await exporter.exportCassette(
          cassette: overview.cassette,
          memos: await memoRepo.memosOf(overview.cassette.id),
          target: target,
        );
      }
      messenger.showSnackBar(SnackBar(
          content: Text(selection.length == 1
              ? l10n.exportedTo(path)
              : l10n.exportedAllTo(selection.length, path))));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.exportFailed('$e'))));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// The exported files read in the app's language too (§13).
  ExportLabels _exportLabels(BuildContext context) {
    final l10n = context.l10n;
    return ExportLabels(
      untitled: l10n.untitledCassette,
      exportedNote: l10n.exportNote,
      summaryHeading: l10n.exportSummaryHeading,
      memoHeading: l10n.memoDivider,
      notTranscribed: l10n.exportNotTranscribed,
      noSpeech: l10n.noSpeech,
    );
  }
}
