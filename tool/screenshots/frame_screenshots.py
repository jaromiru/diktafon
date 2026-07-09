#!/usr/bin/env python3
"""Wraps raw store screenshots in the docs/ui-mockups.html phone frame.

The screenshot test (integration_test/store_screenshots_test.dart) captures
bare 1080x2160 screen contents; this tool publishes each one twice:

  docs/store/screenshots/<name>.png          raw screen — the Play upload
                                             (24-bit RGB, exactly 2:1)
  docs/store/screenshots/<name>-framed.png   presentation version: status bar
                                             (clock + wifi/battery), dark
                                             rounded bezel and a soft drop
                                             shadow on a transparent canvas
  media/{01-home,02-cassette,04-settings}.png   framed README copies

Usage (from the repo root, after the screenshot test):
  python3 tool/screenshots/frame_screenshots.py "$DIKTAFON_TEST_DIR/shots"

The raw set stays alpha-free because Play rejects transparency; the framed
set is RGBA so the surroundings show through outside the phone. Colors and
geometry mirror the phone-frame CSS in docs/ui-mockups.html (.ph / .scr /
.status); dark shots are detected from the screen content.
"""

import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageStat

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
STORE_DIR = os.path.join(ROOT, 'docs', 'store', 'screenshots')
MEDIA_DIR = os.path.join(ROOT, 'media')
README_SET = {'01-home', '02-cassette', '04-settings'}

SHOT_SIZE = (1080, 2160)
S = 3    # px per mockup-CSS logical px (shots are captured @3x)
SS = 4   # supersampling factor for masks and status-bar art

# docs/ui-mockups.html: .ph{border-radius:36px;background:#26241F;padding:10px}
# .scr{border-radius:27px}; phone --p-ink per theme.
BEZEL_COLOR = (0x26, 0x24, 0x1F)
BEZEL_PAD, BEZEL_R, SCREEN_R = 10, 36, 27
INK = {'light': (0x21, 0x1F, 0x1A), 'dark': (0xEC, 0xE8, 0xDF)}
SHADOW_COLOR = (20, 18, 12)

# Status bar: .status{padding:12px 20px 4px;font-size:11.5px;font-weight:700}
STATUS_H = 30            # logical; content band centers on y = 19
STATUS_CY = 19
CLOCK = '17:45'          # the demo dataset is anchored to this afternoon
FONT = os.path.join(ROOT, 'assets', 'fonts', 'SpaceMono-Bold.ttf')

CANVAS = (410, 820)      # logical

def rounded_mask(size_px, radius_px):
    """Antialiased rounded-rect mask (drawn at SSx, downscaled)."""
    w, h = size_px
    m = Image.new('L', (w * SS, h * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [0, 0, w * SS - 1, h * SS - 1], radius_px * SS, fill=255)
    return m.resize(size_px, Image.LANCZOS)


def cast_shadow(canvas, pos, size, radius, dy, sigma, inset, alpha):
    """One box-shadow layer: the phone's rect shrunk by `inset`, offset
    down by `dy`, gaussian-blurred, stamped at `alpha` (all logical px)."""
    x, y = pos
    w, h = size
    m = Image.new('L', canvas.size, 0)
    m.paste(
        rounded_mask((w - 2 * inset * S, h - 2 * inset * S),
                     max(1, radius - inset) * S),
        (x + inset * S, y + (inset + dy) * S))
    m = m.filter(ImageFilter.GaussianBlur(sigma * S))
    layer = Image.new('RGBA', canvas.size, SHADOW_COLOR + (0,))
    layer.putalpha(m.point(lambda v: int(v * alpha)))
    canvas.alpha_composite(layer)


def status_bar(width_px, bg, ink):
    """The mockups' status row: bold clock left, wifi + battery right.
    Drawn at SSx and downscaled; icon paths follow the mockup SVGs."""
    u = S * SS  # px per logical unit while supersampling
    img = Image.new('RGB', (width_px * SS, STATUS_H * u), bg)
    d = ImageDraw.Draw(img)
    cy = STATUS_CY * u

    font = ImageFont.truetype(FONT, int(11.5 * u))
    d.text((20 * u, cy), CLOCK, font=font, fill=ink, anchor='lm')

    # Battery (viewBox 22x11): outline + charge fill + terminal nub.
    bx = img.width - 20 * u - 22 * u
    by = cy - round(5.5 * u)
    d.rectangle([bx, by, bx + 19 * u, by + 11 * u], outline=ink, width=u)
    d.rectangle([bx + 2 * u, by + 2 * u, bx + 14 * u, by + 9 * u], fill=ink)
    d.rectangle([bx + round(19.5 * u), by + round(3.5 * u),
                 bx + round(21.5 * u), by + round(7.5 * u)], fill=ink)

    # Wifi wedge (viewBox 15x12): apex at bottom center, curved top. The
    # 12-tall icon box centers on cy, putting the apex at cy + 6.
    ax, ay, r = bx - 5 * u - round(7.5 * u), cy + 6 * u, 10.7 * u
    d.pieslice([ax - r, ay - r, ax + r, ay + r], 225, 315, fill=ink)

    return img.resize((width_px, STATUS_H * S), Image.LANCZOS)


def frame(shot):
    top = shot.crop((0, 0, shot.width, 8 * S))
    theme = 'dark' if ImageStat.Stat(top.convert('L')).mean[0] < 100 else 'light'
    # Status bg = the shot's own top-edge color, so the bar joins seamlessly.
    colors = top.crop((0, 0, top.width, 4 * S)).getcolors(top.width * 4 * S)
    status_bg = max(colors)[1][:3]

    screen = Image.new('RGB', (shot.width, STATUS_H * S + shot.height))
    screen.paste(status_bar(shot.width, status_bg, INK[theme]), (0, 0))
    screen.paste(shot, (0, STATUS_H * S))

    phone = (screen.width + 2 * BEZEL_PAD * S, screen.height + 2 * BEZEL_PAD * S)
    canvas = Image.new('RGBA', (CANVAS[0] * S, CANVAS[1] * S), (0, 0, 0, 0))
    px = (canvas.width - phone[0]) // 2
    py = (canvas.height - phone[1]) * 2 // 5  # shadow gets the larger margin

    # .ph box-shadow: 0 24px 60px -24px .45 + 0 4px 14px -6px .3 (approx).
    cast_shadow(canvas, (px, py), phone, BEZEL_R, 20, 13, 20, 0.45)
    cast_shadow(canvas, (px, py), phone, BEZEL_R, 4, 5, 4, 0.30)
    bezel = Image.new('RGBA', phone, BEZEL_COLOR + (255,))
    bezel.putalpha(rounded_mask(phone, BEZEL_R * S))
    canvas.alpha_composite(bezel, dest=(px, py))
    scr = screen.convert('RGBA')
    scr.putalpha(rounded_mask(screen.size, SCREEN_R * S))
    canvas.alpha_composite(scr, dest=(px + BEZEL_PAD * S, py + BEZEL_PAD * S))
    return canvas


def main():
    if len(sys.argv) != 2 or not os.path.isdir(sys.argv[1]):
        sys.exit(f'usage: {sys.argv[0]} <raw-shots-dir>')
    shots = sorted(f for f in os.listdir(sys.argv[1]) if f.endswith('.png'))
    if not shots:
        sys.exit(f'no .png shots in {sys.argv[1]}')
    os.makedirs(STORE_DIR, exist_ok=True)
    for name in shots:
        shot = Image.open(os.path.join(sys.argv[1], name)).convert('RGB')
        assert shot.size == SHOT_SIZE, f'{name}: {shot.size} != {SHOT_SIZE}'
        shot.save(os.path.join(STORE_DIR, name))
        framed = frame(shot)
        framed.save(os.path.join(STORE_DIR, f'{name[:-4]}-framed.png'))
        out = [f'{name} + {name[:-4]}-framed.png']
        if name[:-4] in README_SET:
            framed.save(os.path.join(MEDIA_DIR, name))
            out.append(f'media/{name}')
        print(f'  {" + ".join(out)}')


if __name__ == '__main__':
    main()
