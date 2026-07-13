# Transcription quality bench

Phase-0 harness from `docs/features/noise-robust-transcription.md`: scores a
whisper model/engine configuration against the human-verified recordings in
`quality_test/` (gitignored — lives only in the main checkout) and writes
per-clip WER/CER plus pooled aggregates to
`quality_test/results/<variant>.json`. Results append per clip, so an
interrupted run resumes; a finished variant is never re-run (delete its file
to redo it). (The original LLM-cleanup scoring mode left with the retired
§6.8 feature — the phase-0 report proved cleanup WER-inert.)

## Fixtures

`quality_test/*.m4a` with a sibling `*.txt` holding the verified transcript.
The filename carries the spoken language (`*_cs*` / `*_en*`), used as ground
truth for language-detection accounting and for `DIKTAFON_QUALITY_LANG=file`.

## Running one variant

```bash
export PATH="$HOME/Documents/prg/flutter/bin:$PATH"
BENCH=$HOME/.cache/diktafon-quality/models   # model artefacts (not in repo)

DIKTAFON_QUALITY_VARIANT=small \
DIKTAFON_QUALITY_DIR=$HOME/Documents/wrk/diktafon/quality_test \
DIKTAFON_LIBWHISPER=$PWD/build/native-host/libdiktafon_whisper.so \
DIKTAFON_WHISPER_MODEL=$BENCH/ggml-small-q5_1.bin \
flutter test test/quality/transcription_quality_test.dart
```

Optional environment:

| Variable | Effect |
| --- | --- |
| `DIKTAFON_QUALITY_OUT` | results dir (default `<DIR>/results`) |
| `DIKTAFON_QUALITY_FILTER` | ffmpeg `-af` chain on decode (bench-only seam, e.g. `highpass=f=80`, `afftdn`) |
| `DIKTAFON_QUALITY_LANG=file` | force the clip's language instead of auto-detect |
| `DIKTAFON_QUALITY_HPF=<hz>` | Dart high-pass on the decoded PCM (production uses 80 on small/tiny) |
| `DIKTAFON_QUALITY_BEAM=<n>` | beam-search decoding with beam size n |
| `DIKTAFON_QUALITY_VAD=<path>` | Silero VAD ggml model; tuned params are baked in the shim, `DK_WHISPER_VAD_*` env overrides them for sweeps |
| `DIKTAFON_QUALITY_NOTE` | provenance string stored in the results file (branch/commit) |
| `DIKTAFON_QUALITY_RESCORE=1` | re-score cached clips from their stored hypothesis text (after scorer changes) instead of skipping them |

## Scoring

`wer.dart`: lowercase, strip punctuation (diacritics kept), standalone
digits 0–20 spelled out per language ("10" ≍ "deset"), word-level
Levenshtein with S/D/I attribution; WER = (S+D+I)/N over the pooled corpus
(and per language). A literal `[???]` in a reference (a word the verifier
could not discern) matches any one hypothesis word or none, free, and is
excluded from N. CER on the same normalized text. Hypotheses, raw
transcripts (with word timings) and references are stored in the JSON for
inspection.
