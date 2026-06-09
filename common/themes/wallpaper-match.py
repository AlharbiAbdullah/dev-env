#!/usr/bin/env python3
"""
wallpaper-match.py — score how well an image matches a theme's color palette.

Companion to comfort-score.py. The wallpaper SELECTION RULE (the standard) is
written up in README.md; this tool measures the one part that can be measured
objectively — color match — so picks are not guesswork.

Metric: downscale the image, and for every pixel take the distance (CIELAB dE76)
to the NEAREST color in the theme palette (background + 6 chromatic ANSI accents
+ foreground, read live from <theme>/theme.lua). Average a closeness score
(dE 0 -> 1.0, dE >= 40 -> 0) over all pixels. Range 0..100; higher = the image's
colors live inside the palette.

Reference: the themes rated "amazing" score high — nord ~88-99, gruvbox-light
~88-95. Aim for matches in that range; treat <60 as a weak match worth replacing.

Usage:
  python3 common/themes/wallpaper-match.py <theme> <image>...  # score given images
  python3 common/themes/wallpaper-match.py <theme>             # score that theme's installed wallpapers
"""
import glob
import os
import re
import sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))


def parse_palette(theme):
    src = open(os.path.join(HERE, theme, "theme.lua"), encoding="utf-8").read()
    bg = re.search(r'background\s*=\s*"(#[0-9a-fA-F]{6})"', src).group(1)
    fg = re.search(r'foreground\s*=\s*"(#[0-9a-fA-F]{6})"', src).group(1)
    block = re.search(r"ansi\s*=\s*{(.*?)}", src, re.S).group(1)
    ansi = re.findall(r"#[0-9a-fA-F]{6}", block)[:8]
    return [bg] + ansi[1:7] + [fg]   # background + 6 chromatic accents + foreground


def _lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def rgb2lab(r, g, b):
    r, g, b = _lin(r / 255), _lin(g / 255), _lin(b / 255)
    x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047
    y = r * 0.2126 + g * 0.7152 + b * 0.0722
    z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883
    f = lambda t: t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116
    fx, fy, fz = f(x), f(y), f(z)
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))


def hex2lab(h):
    h = h.lstrip("#")
    return rgb2lab(int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def score(theme, path, pal=None):
    pal = pal or [hex2lab(h) for h in parse_palette(theme)]
    im = Image.open(path).convert("RGB").resize((96, 96))
    tot = 0.0
    n = 0
    for (r, g, b) in im.getdata():
        ll, aa, bb = rgb2lab(r, g, b)
        d = min(((ll - pl) ** 2 + (aa - pa) ** 2 + (bb - pb) ** 2) ** 0.5 for (pl, pa, pb) in pal)
        tot += max(0.0, 1.0 - d / 40.0)
        n += 1
    return 100 * tot / n


def main():
    if len(sys.argv) < 2:
        print("usage: wallpaper-match.py <theme> [<image>...]")
        return
    theme = sys.argv[1]
    imgs = sys.argv[2:] or sorted(glob.glob(os.path.join(HERE, theme, "wallpapers", "*")))
    pal = [hex2lab(h) for h in parse_palette(theme)]
    rows = []
    for p in imgs:
        try:
            rows.append((score(theme, p, pal), os.path.basename(p)))
        except Exception as exc:  # noqa: BLE001
            print(f"  skip {os.path.basename(p)}: {exc}")
    for s, name in sorted(rows, reverse=True):
        print(f"{s:5.1f}  {name}")


if __name__ == "__main__":
    main()
