import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../data/repositories/cassette_repository.dart';
import '../theme/tape_colors.dart';
import '../widgets/cassette_card.dart';
import '../widgets/deck.dart';
import 'cassette_screen.dart';
import 'settings_screen.dart';

/// Home — the cassette grid (§5.2, mockup 02): two per row in portrait,
/// recency-sorted, square ink FAB. Long-press a tape → Rename / Delete.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviews = ref.watch(cassetteOverviewsProvider);
    final tape = context.tape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DIKTAFON'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: overviews.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) => items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No cassettes yet.\nPress + to start a new tape.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: tape.ink2),
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 96),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  // Two per row in portrait; more columns on wider screens.
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 157 / 92,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => CassetteCard(
                  overview: items[i],
                  onTap: () => _open(context, items[i].cassette.id),
                  onLongPress: () => _contextMenu(context, ref, items[i]),
                ),
              ),
      ),
      floatingActionButton: DeckKey(
        glyph: DeckGlyph.plus,
        style: DeckKeyStyle.ink,
        width: 54,
        height: 54,
        shadowOffset: 4,
        semanticLabel: 'New cassette',
        onPressed: () async {
          // A new cassette opens immediately with a placeholder label (§5.2).
          final cassette =
              await ref.read(cassetteRepositoryProvider).create();
          if (context.mounted) _open(context, cassette.id);
        },
      ),
    );
  }

  void _open(BuildContext context, String cassetteId) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CassetteScreen(cassetteId: cassetteId)));
  }

  Future<void> _contextMenu(
      BuildContext context, WidgetRef ref, CassetteOverview overview) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.tape.surface,
      shape: Border(top: BorderSide(color: context.tape.ink, width: 2)),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Rename'),
              onTap: () => Navigator.pop(sheetContext, 'rename'),
            ),
            ListTile(
              title: const Text('Delete'),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'rename':
        await showRenameCassetteDialog(context, ref,
            cassetteId: overview.cassette.id,
            currentLabel: overview.cassette.label);
      case 'delete':
        await confirmDeleteCassette(context, ref,
            cassetteId: overview.cassette.id,
            label: overview.cassette.label,
            memoCount: overview.memoCount);
    }
  }
}

/// Shared with the cassette screen's overflow menu.
Future<void> showRenameCassetteDialog(
  BuildContext context,
  WidgetRef ref, {
  required String cassetteId,
  required String? currentLabel,
}) async {
  final controller = TextEditingController(text: currentLabel ?? '');
  final label = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('RENAME CASSETTE'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 48,
        decoration: const InputDecoration(hintText: 'Cassette name'),
        onSubmitted: (v) => Navigator.pop(dialogContext, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: const Text('SAVE'),
        ),
      ],
    ),
  );
  if (label != null) {
    await ref.read(cassetteRepositoryProvider).rename(cassetteId, label);
  }
}

Future<bool> confirmDeleteCassette(
  BuildContext context,
  WidgetRef ref, {
  required String cassetteId,
  required String? label,
  required int memoCount,
}) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('DELETE CASSETTE?'),
          content: Text(
            '"${label ?? 'Untitled cassette'}" and its '
            '$memoCount memo${memoCount == 1 ? '' : 's'} will be deleted. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                  foregroundColor: dialogContext.tape.rec),
              child: const Text('DELETE'),
            ),
          ],
        ),
      ) ??
      false;
  if (confirmed) {
    await ref.read(cassetteRepositoryProvider).delete(cassetteId);
    await ref.read(audioFileStoreProvider).deleteCassetteDir(cassetteId);
  }
  return confirmed;
}
