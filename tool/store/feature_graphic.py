#!/usr/bin/env python3
"""Generates the Google Play feature graphic (1024x500, 24-bit PNG, no alpha).

Composition (approved 2026-07-10, r3): light-paper ground, the pixel
cassette (tape.png, nearest-neighbour x5) left with a hard cardstock
shadow — the raw alpha shape, holes NOT filled, so the shadow shows
through them like the real cutouts. Right block, top to bottom: the
DIKTAFON wordmark (Jersey 10, same hard shadow as the app's deck keys)
centred over the block, the app's timeline bar directly beneath —
coloured memo segments with 2 px-scale gaps and the ink playhead — then
a two-line tagline (Space Mono) after a small margin.
All colours come from lib/presentation/theme/tape_colors.dart (light).

Run from the repo root: `python3 tool/store/feature_graphic.py`
Outputs: docs/store/feature-graphic.png
"""

import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TAPE = os.path.join(ROOT, 'tool', 'icon', 'tape.png')
JERSEY = os.path.join(ROOT, 'assets', 'fonts', 'Jersey10-Regular.ttf')
MONO = os.path.join(ROOT, 'assets', 'fonts', 'SpaceMono-Regular.ttf')
OUT = os.path.join(ROOT, 'docs', 'store', 'feature-graphic.png')

W, H = 1024, 500

# Light-theme tokens (tape_colors.dart) + the six cassette label hues.
PAPER = (0xF5, 0xF4, 0xEF)
INK = (0x21, 0x1F, 0x1A)
INK2 = (0x6F, 0x6A, 0x5E)
LINE = (0xE5, 0xE2, 0xD7)
HUES = [(0xCE, 0x99, 0x30), (0x2F, 0x9C, 0x8D), (0x5E, 0x6C, 0xC9),
        (0xC7, 0x5B, 0x41), (0x7C, 0x94, 0x40), (0x9A, 0x5F, 0xA6)]

TAGLINE = ['Voice memos — transcribed &', 'summarised on your device.']

# Illustrative tape: six memos of varied length, playing mid-fourth memo.
TIMELINE_FRACTIONS = [0.20, 0.10, 0.24, 0.15, 0.19, 0.12]
PLAYHEAD = 0.62


def cassette(scale: int) -> Image.Image:
    src = Image.open(TAPE).convert('RGBA')
    return src.resize((src.width * scale, src.height * scale), Image.NEAREST)


def wordmark_font(draw: ImageDraw.ImageDraw, avail: int) -> ImageFont.FreeTypeFont:
    """Largest Jersey 10 size (multiple of 10, grid-crisp) fitting avail."""
    size = 40
    while True:
        bigger = ImageFont.truetype(JERSEY, size + 10)
        if draw.textlength('DIKTAFON', font=bigger) > avail:
            return ImageFont.truetype(JERSEY, size)
        size += 10


def fit_font(draw: ImageDraw.ImageDraw, text: str, max_size: int,
             avail: int) -> ImageFont.FreeTypeFont:
    for size in range(max_size, 12, -1):
        font = ImageFont.truetype(MONO, size)
        if draw.textlength(text, font=font) <= avail:
            return font
    return ImageFont.truetype(MONO, 12)


def timeline(draw: ImageDraw.ImageDraw, x: float, y: float, width: float,
             bar_h: float = 18, gap: float = 3) -> None:
    """The app's timeline bar at ~1.3x its in-app scale (14 px bar, 2 px
    gaps, 2 px playhead overshooting 6 px with a 9 px square cap)."""
    seg_w = width - gap * (len(TIMELINE_FRACTIONS) - 1)
    cx = x
    for i, fraction in enumerate(TIMELINE_FRACTIONS):
        w = fraction * seg_w
        draw.rectangle([cx, y, cx + w, y + bar_h], fill=HUES[i % len(HUES)])
        cx += w + gap
    px = x + PLAYHEAD * width
    over = 8
    draw.rectangle([px - 1.5, y - over, px + 1.5, y + bar_h + over], fill=INK)
    draw.rectangle([px - 6, y - over - 8, px + 6, y - over + 4], fill=INK)


def main() -> None:
    img = Image.new('RGB', (W, H), PAPER)
    draw = ImageDraw.Draw(img)

    art = cassette(5)                                # 470x295
    ax, ay = 52, (H - art.height) // 2
    # Hard cardstock shadow — deck.dart's BoxShadow(line, offset) scaled up.
    # The raw alpha shape: the shadow shows through the transparent holes.
    shadow = Image.new('RGBA', art.size, LINE + (255,))
    shadow.putalpha(art.getchannel('A'))
    img.paste(shadow, (ax + 10, ay + 10), shadow)
    img.paste(art, (ax, ay), art)

    bx = ax + art.width + 54
    avail = W - bx - 52
    f_word = wordmark_font(draw, avail)
    wbox = draw.textbbox((0, 0), 'DIKTAFON', font=f_word)
    word_w = wbox[2] - wbox[0]
    word_h = wbox[3] - wbox[1]

    f_tag = fit_font(draw, max(TAGLINE, key=len), 29, avail)
    line_h = int(f_tag.size * 1.5)

    cap = 16                                         # playhead above the bar
    gap_word_bar = 16 + cap                          # wordmark -> bar top
    gap_bar_tag = 8 + 28                             # bar bottom -> slogan
    block_h = (word_h + gap_word_bar + 18 + gap_bar_tag
               + len(TAGLINE) * line_h)
    by = (H - block_h) // 2 - wbox[1]                # compensate bbox top

    # Wordmark: the ink glyphs sit exactly centred over the timeline; the
    # shadow hangs off to the right and doesn't count. Font metrics are a
    # few px off the true extents, so centre on the rendered pixels.
    probe = Image.new('L', (word_w + 100, word_h + 100), 0)
    ImageDraw.Draw(probe).text((50, 50), 'DIKTAFON', font=f_word, fill=255)
    mb = probe.getbbox()
    wx = bx + (avail - (mb[2] - mb[0])) // 2 - (mb[0] - 50)
    draw.text((wx + 8, by + 8), 'DIKTAFON', font=f_word, fill=LINE)
    draw.text((wx, by), 'DIKTAFON', font=f_word, fill=INK)
    y = by + wbox[1] + word_h + gap_word_bar
    timeline(draw, bx, y, avail)
    y += 18 + gap_bar_tag
    for tag_line in TAGLINE:
        draw.text((bx, y), tag_line, font=f_tag, fill=INK2)
        y += line_h

    img.save(OUT)
    print(f'{os.path.relpath(OUT, ROOT)} ({img.width}x{img.height}, '
          f'{img.mode}, {os.path.getsize(OUT)} B)')


if __name__ == '__main__':
    sys.exit(main())
