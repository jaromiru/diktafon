import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'content_locale.dart';

/// Free-text editor over a memo's transcription (§6.9). The text arrives and
/// leaves in the [Transcript.plainText] format — one line per segment — and
/// the caller re-times the corrected words onto the engine's grid. Cancel
/// returns null; SAVE is held back while the text is effectively empty
/// (removing content is what delete-memo is for).
Future<String?> showEditTranscriptDialog(
  BuildContext context, {
  required String initialText,
  String? languageCode,
}) {
  final l10n = context.l10n;
  final controller = TextEditingController(text: initialText);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.editTranscriptTitle),
      content: SizedBox(
        width: double.maxFinite,
        height: min(320, MediaQuery.sizeOf(dialogContext).height * 0.45),
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          style: TextStyle(
            fontSize: 13,
            height: 1.6,
            // Han unification (§13): the transcript is content in the
            // memo's language, not UI chrome.
            locale: contentLocale(languageCode),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, child) => TextButton(
            onPressed: value.text.trim().isEmpty
                ? null
                : () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.save),
          ),
        ),
      ],
    ),
  );
}
