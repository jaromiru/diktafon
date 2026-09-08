/// Row ↔ domain mapping kept in one place so the schema can evolve without
/// touching call sites.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;

import '../../domain/models.dart';
import '../db/database.dart';

DateTime _fromMs(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

Cassette cassetteFromRow(CassetteRow row) => Cassette(
      id: row.id,
      label: row.label,
      titleIsUserSet: row.titleIsUserSet,
      colorSeed: row.colorSeed,
      summary: row.summary,
      summaryUpdatedAt:
          row.summaryUpdatedAt == null ? null : _fromMs(row.summaryUpdatedAt!),
      createdAt: _fromMs(row.createdAt),
      updatedAt: _fromMs(row.updatedAt),
    );

/// Long transcripts are thousands of word objects; parsing them on the UI
/// isolate stalled frames on phones, so tape loads decode pooled (one
/// [transcriptsFromJsonAsync] call per batch). [memoFromRow] itself stays
/// sync: pass the decoded [transcript] in, or it decodes inline (fine for
/// small/single rows).
Memo memoFromRow(MemoRow row, {Transcript? transcript}) => Memo(
      id: row.id,
      cassetteId: row.cassetteId,
      filePath: row.filePath,
      durationMs: row.durationMs,
      createdAt: _fromMs(row.createdAt),
      status: MemoStatus.fromName(row.status),
      detectedLang: row.detectedLang,
      transcript: row.transcript == null
          ? null
          : (transcript ?? transcriptFromJson(row.transcript!)),
      memoSummary: row.memoSummary,
    );

/// Synchronous decode for the common (small) case.
Transcript transcriptFromJson(String json) =>
    Transcript.fromJson(jsonDecode(json) as Map<String, dynamic>);

/// Pooled batch decode for tape loads: a whole cassette's rows go through
/// here whenever the memo table changes; nulls align with [jsons].
Future<List<Transcript?>> transcriptsFromJsonAsync(List<String?> jsons) =>
    compute(_decodeTranscripts, jsons);

List<Transcript?> _decodeTranscripts(List<String?> jsons) => [
      for (final json in jsons)
        json == null
            ? null
            : Transcript.fromJson(jsonDecode(json) as Map<String, dynamic>),
    ];

/// Pooled encode for transcript writes (word-level JSON is the largest
/// blob the app stores).
Future<String> transcriptToJsonAsync(Transcript transcript) =>
    compute(_encodeTranscript, transcript);

String _encodeTranscript(Transcript transcript) =>
    jsonEncode(transcript.toJson());
