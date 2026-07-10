#!/usr/bin/env python3
"""Wraps raw store screenshots in the docs/ui-mockups.html device frame.

The screenshot test (integration_test/store_screenshots_test.dart) captures
bare 9:16 screen contents for one device profile per run; this tool publishes
each shot twice:

  docs/store/screenshots/<device>/<name>.png   raw screen — the Play upload
                                               (24-bit RGB, exactly 9:16)
  docs/store/screenshots/<device>/framed/<name>-framed.png
                                               presentation version: status
                                               bar (clock + wifi/battery),
                                               dark rounded bezel and a soft
                                               drop shadow on a transparent
                                               canvas
  media/{01-home,02-cassette,04-settings}.png  framed README copies
                                               (phone profile only)

Usage (from the repo root, after the screenshot test):
  python3 tool/screenshots/frame_screenshots.py --device phone \
      "$DIKTAFON_TEST_DIR/shots"

Device profiles match DIKTAFON_SHOT_PROFILE in the test:
  phone     1080x1920 @3x   -> screenshots/phone/
  tablet7   1206x2144 @2x   -> screenshots/tablet-7in/
  tablet10  1440x2560 @2x   -> screenshots/tablet-10in/

The raw set stays alpha-free because Play rejects transparency; the framed
set is RGBA so the surroundings show through outside the device. Colors and
geometry mirror the phone-frame CSS in docs/ui-mockups.html (.ph / .scr /
.status), with flatter corners and a wider bezel for the tablets; dark shots
are detected from the screen content.
"""

import argparse
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageStat

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
STORE_DIR = os.path.join(ROOT, 'docs', 'store', 'screenshots')
MEDIA_DIR = os.path.join(ROOT, 'media')
README_SET = {'01-home', '02-cassette', '04-settings'}

# Per-device geometry, all logical px (the mockup-CSS unit). `s` is the px
# per logical px the shot was captured at. Phone values are straight from
# docs/ui-mockups.html: .ph{border-radius:36px;padding:10px}
# .scr{border-radius:27px}; tablets get a wider bezel and flatter corners.
PROFILES = {
    'phone': dict(shot=(1080, 1920), s=3, dir='phone',
                  bezel_pad=10, bezel_r=36, screen_r=27, readme=True),
    'tablet7': dict(shot=(1206, 2144), s=2, dir='tablet-7in',
                    bezel_pad=16, bezel_r=34, screen_r=20, readme=False),
    'tablet10': dict(shot=(1440, 2560), s=2, dir='tablet-10in',
                     bezel_pad=18, bezel_r=36, screen_r=20, readme=False),
}

SS = 4   # supersampling factor for masks and status-bar art

BEZEL_COLOR = (0x26, 0x24, 0x1F)
INK = {'light': (0x21, 0x1F, 0x1A), 'dark': (0xEC, 0xE8, 0xDF)}
SHADOW_COLOR = (20, 18, 12)

# Status bar: .status{padding:12px 20px 4px;font-size:11.5px;font-weight:700}
STATUS_H = 30            # logical; content band centers on y = 19
STATUS_CY = 19
CLOCK = '17:45'          # the demo dataset is anchored to this afternoon
FONT = os.path.join(ROOT, 'assets', 'fonts', 'SpaceMono-Bold.ttf')

# Transparent margin around the framed device: sides / vertical (logical).
MARGIN_W, MARGIN_H = 30, 50


def rounded_mask(size_px, radius_px):
    """Antialiased rounded-rect mask (drawn at SSx, downscaled)."""
    w, h = size_px
    m = Image.new('L', (w * SS, h * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [0, 0, w * SS - 1, h * SS - 1], radius_px * SS, fill=255)
    return m.resize(size_px, Image.LANCZOS)


def cast_shadow(canvas, pos, size, radius, dy, sigma, inset, alpha, s):
    """One box-shadow layer: the device's rect shrunk by `inset`, offset
    down by `dy`, gaussian-blurred, stamped at `alpha` (all logical px)."""
    x, y = pos
    w, h = size
    m = Image.new('L', canvas.size, 0)
    m.paste(
        rounded_mask((w - 2 * inset * s, h - 2 * inset * s),
                     max(1, radius - inset) * s),
        (x + inset * s, y + (inset + dy) * s))
    m = m.filter(ImageFilter.GaussianBlur(sigma * s))
    layer = Image.new('RGBA', canvas.size, SHADOW_COLOR + (0,))
    layer.putalpha(m.point(lambda v: int(v * alpha)))
    canvas.alpha_composite(layer)


def status_bar(width_px, bg, ink, s):
    """The mockups' status row: bold clock left, wifi + battery right.
    Drawn at SSx and downscaled; icon paths follow the mockup SVGs."""
    u = s * SS  # px per logical unit while supersampling
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

    return img.resize((width_px, STATUS_H * s), Image.LANCZOS)


def frame(shot, p):
    s = p['s']
    top = shot.crop((0, 0, shot.width, 8 * s))
    theme = 'dark' if ImageStat.Stat(top.convert('L')).mean[0] < 100 else 'light'
    # Status bg = the shot's own top-edge color, so the bar joins seamlessly.
    colors = top.crop((0, 0, top.width, 4 * s)).getcolors(top.width * 4 * s)
    status_bg = max(colors)[1][:3]

    screen = Image.new('RGB', (shot.width, STATUS_H * s + shot.height))
    screen.paste(status_bar(shot.width, status_bg, INK[theme], s), (0, 0))
    screen.paste(shot, (0, STATUS_H * s))

    pad = p['bezel_pad']
    device = (screen.width + 2 * pad * s, screen.height + 2 * pad * s)
    canvas = Image.new(
        'RGBA',
        (device[0] + MARGIN_W * s, device[1] + MARGIN_H * s), (0, 0, 0, 0))
    px = (canvas.width - device[0]) // 2
    py = (canvas.height - device[1]) * 2 // 5  # shadow gets the larger margin

    # .ph box-shadow: 0 24px 60px -24px .45 + 0 4px 14px -6px .3 (approx).
    cast_shadow(canvas, (px, py), device, p['bezel_r'], 20, 13, 20, 0.45, s)
    cast_shadow(canvas, (px, py), device, p['bezel_r'], 4, 5, 4, 0.30, s)
    bezel = Image.new('RGBA', device, BEZEL_COLOR + (255,))
    bezel.putalpha(rounded_mask(device, p['bezel_r'] * s))
    canvas.alpha_composite(bezel, dest=(px, py))
    scr = screen.convert('RGBA')
    scr.putalpha(rounded_mask(screen.size, p['screen_r'] * s))
    canvas.alpha_composite(scr, dest=(px + pad * s, py + pad * s))
    return canvas


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--device', choices=sorted(PROFILES), default='phone')
    ap.add_argument('shots_dir')
    args = ap.parse_args()
    p = PROFILES[args.device]
    if not os.path.isdir(args.shots_dir):
        raise SystemExit(f'not a directory: {args.shots_dir}')
    shots = sorted(f for f in os.listdir(args.shots_dir) if f.endswith('.png'))
    if not shots:
        raise SystemExit(f'no .png shots in {args.shots_dir}')
    raw_dir = os.path.join(STORE_DIR, p['dir'])
    framed_dir = os.path.join(raw_dir, 'framed')
    os.makedirs(framed_dir, exist_ok=True)
    for name in shots:
        shot = Image.open(os.path.join(args.shots_dir, name)).convert('RGB')
        expected = tuple(p['shot'])
        assert shot.size == expected, f'{name}: {shot.size} != {expected}'
        shot.save(os.path.join(raw_dir, name))
        framed = frame(shot, p)
        framed.save(os.path.join(framed_dir, f'{name[:-4]}-framed.png'))
        out = [f'{p["dir"]}/{name} + framed/{name[:-4]}-framed.png']
        if p['readme'] and name[:-4] in README_SET:
            framed.save(os.path.join(MEDIA_DIR, name))
            out.append(f'media/{name}')
        print(f'  {" + ".join(out)}')


if __name__ == '__main__':
    main()
