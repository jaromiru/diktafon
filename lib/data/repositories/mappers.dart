/// Row ↔ domain mapping kept in one place so the schema can evolve without
/// touching call sites.
library;

import 'dart:convert';

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

Memo memoFromRow(MemoRow row) => Memo(
      id: row.id,
      cassetteId: row.cassetteId,
      filePath: row.filePath,
      durationMs: row.durationMs,
      createdAt: _fromMs(row.createdAt),
      status: MemoStatus.fromName(row.status),
      detectedLang: row.detectedLang,
      transcript: row.transcript == null
          ? null
          : Transcript.fromJson(
              jsonDecode(row.transcript!) as Map<String, dynamic>),
      memoSummary: row.memoSummary,
    );
