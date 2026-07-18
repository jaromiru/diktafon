# Changelog

All notable changes to Diktafon are documented in this file. Versions
correspond to git tags (`v*`); dates are tag dates.

## [1.0.4] — 2026-07-18

### Changed
- Android APKs no longer embed Google Play's encrypted dependency-info
  signing block (F-Droid's scanner rejects it). Packaging-only release —
  no functional changes.

## [1.0.3] — 2026-07-17

### Added
- F-Droid packaging metadata (fastlane en-US listing: description, icon,
  feature graphic, screenshots, per-release changelogs).

### Changed
- **Clearer transcripts** — voice-activity detection ships bundled
  (Silero VAD): the small/tiny whisper tiers get an 80 Hz high-pass plus
  full VAD, large-v3-turbo gets a speech gate that skips transcription of
  speechless audio entirely; non-speech token suppression is on for all
  tiers. Cuts background-noise ghost words and hallucinations.
- Android recording now uses the `VOICE_RECOGNITION` capture source
  (flat response, OEM noise-suppression/AGC off) for better transcription.
- **Snappier summaries** — memo gists are a single short sentence, memos
  with transcripts under 350 characters skip the summary step entirely,
  cassette overviews fold in transcript digests for memos without a gist,
  and suggested cassette titles now name the topic ("Shopping list")
  instead of compressing the overview.
- LLM transcript cleanup removed (measured to have no effect on word error
  rate at real cost); the Settings toggle is gone.
- **Pixel-art home grid** — cassette tiles are now the app icon's sprite:
  each cassette keeps its accent colour, the wound tape grows with
  recorded time, and the name is printed on the label. In dark theme the
  shell tone is lifted so tiles stay legible on the dark shelf.
- Settings polish: the whisper model picker recommends large-v3-turbo on
  devices with enough RAM; the Summaries toggle merged into the summary
  model picker as a "No summaries" option; model descriptions are now
  localized in all 10 languages.
- Reading screens widened to a 720 px content column (10″ tablets fill
  their width).

### Fixed
- Memos no longer get stuck at "transcribing" forever after Android kills
  the backgrounded app mid-job — interrupted jobs are recovered and
  re-queued on next launch, and existing stuck memos self-heal.
- Job-queue self-healing: transient failures reset the memo's status,
  waiting memos with no live job are re-enqueued once per launch, and
  finished job rows are pruned.
- Recording start is guarded against double-taps and failures now surface
  as a snackbar; backgrounding the app on Android finalizes the in-flight
  memo instead of losing it.
- Playback errors and missing audio files are reported instead of failing
  silently.
- Android playback decoding streams instead of buffering the whole file
  (out-of-memory crashes on hour-long memos).
- Model downloads detect stalled connections (30 s timeout) instead of
  hanging.
- Cursor no longer wiggles when pressing play right after tapping a
  transcript word.

## [1.0.2] — 2026-07-12

### Added
- **iOS port** — the app runs on iPhone and iPad: whisper.cpp/llama.cpp as
  embedded frameworks, native audio decode, zip save through the document
  picker, RAM-gated model catalog; App Store submission prep (encryption
  exemption, models excluded from iCloud backup).
- Transcript follows seeks: scrubbing, segment/word taps, and ±15 s keep
  the highlighted word comfortably in view.
- Privacy-policy link in the About dialog (all locales).
- Release CI: iOS build job producing an unsigned ipa.

### Changed
- Wide-screen polish: reading screens center content in a column, home
  grid tiles grew for iPad/tablet layouts.
- Download pause polish: resuming starts the progress bar at the saved
  percentage; paused rows wrap on narrow screens.

### Fixed
- iOS device-pass fixes: import picker silently doing nothing; app-wide
  UI freezes while summaries ran (LLM inference pinned to CPU); old tapes
  unplayable after an app update (iOS moves the data container — audio
  paths are now re-based at launch).
- Switching cassettes no longer carries the previous tape's playback
  position; each tape remembers its own spot.
- Cross-memo seeks landing at the wrong position on iOS/Android.

## [1.0.1] — 2026-07-10

### Changed
- Rewind/transport controls centered.
- App icons regenerated; store feature graphic added.
- English copy standardized to en-GB spellings.

### Added
- Privacy policy (`PRIVACY.md`).
- Store screenshots: 5 screens × light/dark across phone and tablet
  profiles.

## [1.0.0] — 2026-07-09

First public release.

- Voice memos on cassettes rendered as one continuous tape: record,
  gapless playback, timeline and transport controls, light/dark theme.
- On-device transcription (whisper.cpp) with word-level timestamps and
  tap-to-seek; per-memo language auto-detect with an optional override;
  downloadable, checksum-pinned models with pause/resume and progress
  notifications.
- On-device summaries (llama.cpp + Qwen3): memo gists, cassette
  overviews, and title suggestions — no data ever leaves the device.
- First-run setup flow guiding model downloads.
- Zip export and additive import of cassettes (audio + transcript +
  manifest).
- Boundary chime between memos, per-memo copy/delete, cassette colors,
  retranscribe-cassette.
- 10 UI languages: en, cs, de, es, fr, pl, pt, ru, tr, ko; accessibility
  (semantic timeline slider, reduced-motion support).
- Android and Linux desktop builds; release CI with per-ABI APKs, signed
  builds, and provenance attestation.

[1.0.4]: https://github.com/jaromiru/diktafon/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/jaromiru/diktafon/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/jaromiru/diktafon/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/jaromiru/diktafon/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/jaromiru/diktafon/releases/tag/v1.0.0
