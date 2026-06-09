#!/usr/bin/env python3
"""
comfort-score.py — rank theme.lua palettes by eye comfort.

Scores every theme in this directory (common/themes/<name>/theme.lua) on a
0-100 "eye comfort" scale, derived empirically from a hand ranking of the
themes that are comfortable to stare at all day vs the ones that strain.

THE FORMULA — equal-weight average of three factors, each normalized to 0..1:

    comfort = 100 * (bg_lift + warmth + calm) / 3

    bg_lift = clamp((bgL* - 8) / 14)
        Background lifted off near-black. A near-black field dilates the pupil
        and makes text glare; a lifted dark-grey is gentle.
        (CIELAB L*: ~7 = near-black, ~22 = the lightest dark backgrounds.)

    warmth  = clamp(((R - B)*255 + 20) / 80)         # R,B of the foreground
        Warm (tan/amber) text reads softer than cold blue-white, or than a
        clinical neutral grey -- the "white text" that strains.

    calm    = 1 - clamp((scream - 0.60) / 0.40)
        A veto on a single screaming color. scream = the loudest color in the
        palette = max over the 6 chromatic ANSI slots of (HSV saturation x value).
        A neon yellow (#ffc600) maxes it; an earthy coral (#ea6962) does not.

WHY THESE THREE: they are the factors that survived testing against the actual
ranking. A foreground/background lightness *gap* term and an average-saturation
term were both tried and discarded (they mispredict). Crucially this formula
contains NO theme-specific term -- yet the two favorites, everforest and
gruvbox, surface as #1 and #2 on their own, because each maxes one axis
(everforest = lightest background, gruvbox = warmest text). An equal blend of
the two axes is the only thing that puts both on top together.

TRUST BOUNDARY (be honest about it):
  * Solid: the TOP (everforest/gruvbox) and the neon-screamer BOTTOM (cobalt2).
    Both are pinned hard.
  * Noise: the middle order (#3-#11). With only ~7 rated themes against several
    factors it cannot be fit without overfitting -- do not over-read small
    differences there.
  * Open signal (needs more ratings, NOT more weight-tuning): the ranking hints
    background-lift should outweigh warmth (nord is liked despite cold text, for
    its very lifted background), and that "no single scream" should perhaps be
    "no overall loudness" (bamboo has no one screaming color but is broadly
    colorful, and is ranked down).

Usage:  python3 common/themes/comfort-score.py
"""
import colorsys
import glob
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def _lin(c):
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def lstar(h):
    """CIELAB perceptual lightness, 0 (black) .. 100 (white)."""
    r, g, b = rgb(h)
    y = 0.2126 * _lin(r) + 0.7152 * _lin(g) + 0.0722 * _lin(b)
    return 116 * y ** (1 / 3) - 16 if y > 0.008856 else y * 903.3


def clamp(x):
    return max(0.0, min(1.0, x))


def parse_theme(path):
    src = open(path, encoding="utf-8").read()
    bg = re.search(r'background\s*=\s*"(#[0-9a-fA-F]{6})"', src).group(1)
    fg = re.search(r'foreground\s*=\s*"(#[0-9a-fA-F]{6})"', src).group(1)
    block = re.search(r"ansi\s*=\s*{(.*?)}", src, re.S).group(1)
    ansi = re.findall(r"#[0-9a-fA-F]{6}", block)[:8]
    return bg, fg, ansi


def score(bg, fg, ansi):
    bg_l = lstar(bg)
    r, _, b = rgb(fg)
    warmth = (r - b) * 255
    chromatic = ansi[1:7]  # red, green, yellow, blue, magenta, cyan
    scream = max(
        colorsys.rgb_to_hsv(*rgb(c))[1] * colorsys.rgb_to_hsv(*rgb(c))[2]
        for c in chromatic
    )
    bg_lift = clamp((bg_l - 8) / 14)
    warm = clamp((warmth + 20) / 80)
    calm = 1 - clamp((scream - 0.60) / 0.40)
    return 100 * (bg_lift + warm + calm) / 3, bg_lift, warm, calm


def main():
    rows = []
    for path in sorted(glob.glob(os.path.join(HERE, "*", "theme.lua"))):
        name = os.path.basename(os.path.dirname(path))
        try:
            bg, fg, ansi = parse_theme(path)
            if len(ansi) < 7:
                raise ValueError("need >= 7 ANSI colors")
            rows.append((name, *score(bg, fg, ansi)))
        except Exception as exc:  # noqa: BLE001 - report and keep going
            print(f"  skip {name}: {exc}")
    rows.sort(key=lambda x: -x[1])
    print(f"\n{'#':>2}  {'theme':16} {'comfort':>7} | {'bg':>4} {'warm':>4} {'calm':>4}")
    print("-" * 46)
    for i, (name, sc, a, b, c) in enumerate(rows, 1):
        print(f"{i:>2}  {name:16} {sc:7.1f} | {a:4.2f} {b:4.2f} {c:4.2f}")


if __name__ == "__main__":
    main()
