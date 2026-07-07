/// Timeline palette logic (§10.2) — pure index math; the actual light/dark
/// colors live in the presentation theme.
library;

/// Number of tape hues (ochre, teal, indigo, rust, moss, plum).
const int tapeHueCount = 6;

/// The hue list is curated so *neighbouring entries always contrast*; cycling
/// by tape position therefore guarantees adjacent memos contrast (§10.2), and
/// `colorSeed` rotates the cycle so each cassette looks stable but distinct.
int memoHueIndex(int colorSeed, int memoPosition) =>
    (colorSeed + memoPosition) % tapeHueCount;

/// The single accent stripe identifying a cassette on the home grid (§5.2).
int cassetteHueIndex(int colorSeed) => colorSeed % tapeHueCount;
