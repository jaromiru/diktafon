import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../data/repositories/cassette_repository.dart';
import '../../domain/models.dart';
import '../../l10n/l10n.dart';
import '../../services/export/cassette_exporter.dart';
import '../../services/system/system_settings.dart';
import '../theme/tape_colors.dart';
import '../widgets/content_width.dart';
import '../widgets/settings_rows.dart';

/// Backup, export & import (§8): OS backup covers the metadata
/// automatically; large audio travels in explicit, user-initiated `.zip`
/// archives — one cassette or the whole shelf — which the Import row
/// brings back in (D14: additive, never destructive).
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _exporting = false;
  bool _importing = false;

  bool get _busy => _exporting || _importing;

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
      body: ContentWidth(
          child: ListView(
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
              onTap: _busy || overviews.isEmpty
                  ? null
                  : () => _export(overviews),
            ),
            for (final overview in overviews)
              SettingsRow(
                title: overview.cassette.label ?? l10n.untitledCassette,
                value: l10n.memoCount(overview.memoCount),
                onTap: _busy ? null : () => _export([overview]),
              ),
          ]),
          SettingsGroup(title: l10n.groupImport, rows: [
            SettingsRow(
              title: l10n.importArchive,
              value: _importing ? l10n.importing : l10n.importArchiveDesc,
              onTap: _busy ? null : _import,
            ),
          ]),
        ],
      )),
    );
  }

  Future<void> _export(List<CassetteOverview> selection) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final labels = _exportLabels(context);
    final suggested = _suggestedName(selection, l10n.untitledCassette);

    // Desktop saves straight into the picked location; mobile file_selector
    // has no save dialog, so the zip is staged in the cache and handed to
    // the OS save dialog (SAF / iOS export picker) afterwards.
    String outputPath;
    Directory? staging;
    if (useMobileSaveFlow) {
      staging = await Directory.systemTemp.createTemp('diktafon_export_zip_');
      outputPath = '${staging.path}/$suggested';
    } else {
      final location = await getSaveLocation(
        suggestedName: suggested,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'zip', extensions: ['zip'])
        ],
      );
      if (location == null || !mounted) return; // user cancelled the picker
      outputPath = location.path;
      // Desktop save dialogs don't force an extension, and import dispatches
      // on it — a bare name would export fine but never import back.
      if (!outputPath.toLowerCase().endsWith('.zip')) {
        outputPath = '$outputPath.zip';
      }
    }

    setState(() => _exporting = true);
    try {
      final memoRepo = ref.read(memoRepositoryProvider);
      final items = <({Cassette cassette, List<Memo> memos})>[
        for (final overview in selection)
          (
            cassette: overview.cassette,
            memos: await memoRepo.memosOf(overview.cassette.id),
          ),
      ];
      await CassetteExporter(labels: labels)
          .exportArchive(items: items, outputPath: outputPath);

      var shownPath = outputPath;
      if (useMobileSaveFlow) {
        final saved = await saveDocumentMobile(
            sourcePath: outputPath, suggestedName: suggested);
        if (!saved) return; // backed out of the OS dialog — not an error
        shownPath = suggested; // content URIs are opaque; name the file
      }
      messenger.showSnackBar(SnackBar(
          content: Text(selection.length == 1
              ? l10n.exportedTo(shownPath)
              : l10n.exportedAllTo(selection.length, shownPath))));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.exportFailed('$e'))));
    } finally {
      if (staging != null) {
        try {
          await staging.delete(recursive: true);
        } catch (_) {}
      }
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _import() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    // Before anything happens, say what an import does (D14): cassettes are
    // added next to the existing ones, nothing is deleted, and re-importing
    // what is already here duplicates it.
    final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.importDialogTitle),
            content: Text(l10n.importDialogBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.importAction),
              ),
            ],
          ),
        ) ??
        false;
    if (!proceed || !mounted) return;

    // Every platform reads a different XTypeGroup field; iOS *throws* on a
    // group without UTIs — and asynchronously, so keep the picker inside a
    // catch or a failure is an invisible no-op.
    final XFile? file;
    try {
      file = await openFile(acceptedTypeGroups: const [
        XTypeGroup(
            label: 'zip',
            extensions: ['zip'],
            mimeTypes: ['application/zip'],
            uniformTypeIdentifiers: ['public.zip-archive']),
      ]);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importFailed('$e'))));
      return;
    }
    if (file == null || !mounted) return;

    setState(() => _importing = true);
    try {
      final result = await ref
          .read(cassetteImporterProvider)
          .importArchive(File(file.path));
      if (result.isEmpty) {
        messenger
            .showSnackBar(SnackBar(content: Text(l10n.importNothingFound)));
      } else {
        var text = l10n.importedResult(result.cassettes, result.memos);
        if (result.failures.isNotEmpty) {
          text = '$text ${l10n.importFailures(result.failures.length)}';
        }
        messenger.showSnackBar(SnackBar(content: Text(text)));
      }
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.importFailed('$e'))));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _suggestedName(List<CassetteOverview> selection, String untitled) =>
      selection.length == 1
          ? '${CassetteExporter.fileSafe(selection.single.cassette.label ?? untitled)}.zip'
          : 'diktafon-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.zip';

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
