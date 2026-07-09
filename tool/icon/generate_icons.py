#!/usr/bin/env python3
"""Generates every app icon from the pixel-art source (tape.png, 94x59).

The pixel art is upscaled with nearest-neighbour only (integer factors, so
the pixels stay square), composed onto masters, and the masters are
downscaled with Lanczos to the individual target sizes — crisp pixel look
at large sizes, clean anti-aliasing at launcher sizes.

Outputs (run from the repo root: `python3 tool/icon/generate_icons.py`):
  android/.../mipmap-*/ic_launcher.png            legacy launcher icons
  android/.../mipmap-*/ic_launcher_foreground.png adaptive foreground
  android/.../mipmap-*/ic_launcher_monochrome.png Android 13 themed icon
  android/.../mipmap-anydpi-v26/ic_launcher.xml   adaptive icon definition
  android/.../values/ic_launcher_background.xml   background color
  ios/Runner/Assets.xcassets/AppIcon.appiconset/  all sizes in Contents.json
  linux/runner/resources/icon.png                 GTK window icon (256)
  media/icon.png                                  README icon (transparent)
  docs/store/icon-512.png                         Play Store listing icon
"""

import json
import os
import sys

from PIL import Image

# The app's light-theme paper color (lib/presentation/theme/tape_colors.dart).
PAPER = (0xF5, 0xF4, 0xEF, 0xFF)

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, 'tool', 'icon', 'tape.png')

ANDROID_RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}


def nn_upscale(img: Image.Image, factor: int) -> Image.Image:
    return img.resize((img.width * factor, img.height * factor), Image.NEAREST)


def compose(canvas_px: int, cassette: Image.Image, background) -> Image.Image:
    out = Image.new('RGBA', (canvas_px, canvas_px), background)
    out.alpha_composite(
        cassette,
        ((canvas_px - cassette.width) // 2, (canvas_px - cassette.height) // 2),
    )
    return out


def scaled(master: Image.Image, size: int) -> Image.Image:
    return master.resize((size, size), Image.LANCZOS)


def save(img: Image.Image, path: str, opaque: bool = False) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if opaque:
        img = img.convert('RGB')
    img.save(path)
    print(f'  {os.path.relpath(path, ROOT)} ({img.width}x{img.height})')


def main() -> None:
    src = Image.open(SRC).convert('RGBA')
    assert src.size == (94, 59), f'unexpected source size {src.size}'

    # Full-bleed master (legacy/desktop/store): cassette at 16x = 73 % width.
    legacy = compose(2048, nn_upscale(src, 16), PAPER)

    # Adaptive foreground master: the 108 dp adaptive canvas guarantees only
    # a 66 dp circle; 11x keeps the cassette's corners inside that circle.
    fg = compose(2048, nn_upscale(src, 11), (0, 0, 0, 0))

    # Themed-icon (monochrome) master: the launcher tints the alpha shape.
    silhouette = Image.new('RGBA', fg.size, (255, 255, 255, 255))
    silhouette.putalpha(fg.getchannel('A'))

    print('Android:')
    for density, mult in DENSITIES.items():
        d = os.path.join(ANDROID_RES, f'mipmap-{density}')
        save(scaled(legacy, int(48 * mult)), os.path.join(d, 'ic_launcher.png'))
        save(scaled(fg, int(108 * mult)),
             os.path.join(d, 'ic_launcher_foreground.png'))
        save(scaled(silhouette, int(108 * mult)),
             os.path.join(d, 'ic_launcher_monochrome.png'))

    anydpi = os.path.join(ANDROID_RES, 'mipmap-anydpi-v26')
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, 'ic_launcher.xml'), 'w') as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
''')
    with open(os.path.join(ANDROID_RES, 'values',
                           'ic_launcher_background.xml'), 'w') as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#F5F4EF</color>
</resources>
''')
    print('  mipmap-anydpi-v26/ic_launcher.xml + values/ic_launcher_background.xml')

    print('iOS (opaque, as required):')
    iconset = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets',
                           'AppIcon.appiconset')
    seen = set()
    for entry in json.load(open(os.path.join(iconset, 'Contents.json')))['images']:
        name = entry['filename']
        if name in seen:
            continue
        seen.add(name)
        points = float(entry['size'].split('x')[0])
        scale = int(entry['scale'].rstrip('x'))
        save(scaled(legacy, int(round(points * scale))),
             os.path.join(iconset, name), opaque=True)

    print('Desktop / repo / store:')
    save(scaled(legacy, 256),
         os.path.join(ROOT, 'linux', 'runner', 'resources', 'icon.png'))
    # README header icon: the cassette alone — transparent, no square canvas,
    # so it sits inline next to the title on both GitHub themes.
    save(nn_upscale(src, 16).resize((src.width * 4, src.height * 4),
                                    Image.LANCZOS),
         os.path.join(ROOT, 'media', 'icon.png'))
    save(scaled(legacy, 512),
         os.path.join(ROOT, 'docs', 'store', 'icon-512.png'), opaque=True)


if __name__ == '__main__':
    sys.exit(main())
