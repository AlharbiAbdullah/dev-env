# common/themes

14 shared theme definitions, consumed 1:1 by both the macOS and Ubuntu setups.
Each `<name>/theme.lua` is a declarative palette (background, foreground, cursor,
selection, 8 ANSI + 8 bright colors) plus a `wallpapers/` pack.

## comfort-score.py

Ranks every theme on a 0–100 **eye-comfort** scale, computed straight from the
`theme.lua` palettes. Run it:

```bash
python3 common/themes/comfort-score.py
```

### The formula

`comfort = 100 × (bg_lift + warmth + calm) / 3` — equal weight, three factors, each 0–1:

| factor | what it measures | why it matters |
|---|---|---|
| **bg_lift** | background lifted off near-black (CIELAB L\*) | a near-black field dilates the pupil → everything glares |
| **warmth** | warm/amber foreground (R−B of the text) | warm text reads softer than cold blue-white or a clinical neutral "white" grey |
| **calm** | veto on the loudest single color (max HSV sat×value across the palette) | one screaming neon disqualifies a theme; earthy-but-saturated is fine |

Derived empirically from a hand ranking of which themes are comfortable all day.
It has **no theme-specific term** — yet the two favorites, **everforest** and
**gruvbox**, come out #1 and #2 on their own, because each maxes one axis
(everforest = lightest background, gruvbox = warmest text). An equal blend of the
two axes is the only thing that lands both on top together.

### Trust boundary

- **Solid:** the top (everforest / gruvbox) and the neon-screamer bottom (cobalt2).
- **Noise:** the middle (#3–#11) is underdetermined from the current ratings — don't over-read small differences.

Full rationale, the discarded factors (lightness *gap*, average saturation), and
the open questions live in the `comfort-score.py` docstring.

## Wallpapers — the standard

Each theme's `wallpapers/` holds **3** hand-picked images. They must satisfy all of:

**Aesthetic**
- **Art, dark.** Anime / illustration, digital art, minimalist, abstract, geometric, pixel-art. Stylized, not photographic.
- **No women or girls.** No female figures or characters. Other figures — including anime (male/neutral) — are fine.
- **No real-world photography.** No nature/forests/mountains, no coffee/food/drinks, no cities/buildings.
- **Vary composition.** Centered subjects are fine but don't overuse them — mix full-bleed patterns, gradients, stylized landscapes, geometric, the occasional centered piece.

**Color match (hard requirement)**
- Each wallpaper must closely match its theme's palette. Verify objectively:
  ```bash
  python3 common/themes/wallpaper-match.py <theme> <image>...   # score candidates
  python3 common/themes/wallpaper-match.py <theme>              # score installed wallpapers
  ```
  Scores 0–100 by per-pixel nearest-palette distance (CIELAB). The reference "amazing" themes score **nord ~88–99, gruvbox-light ~88–95**. Aim high; treat **<60** as a weak match worth replacing.

**Format & fit**
- 3 per theme, **16:9 aspect** (both displays are 16:9 — Linux QHD 2560×1440, Mac FHD 1920×1080), so swaybg/`-m fill` shows the whole image with no cropping.
- **Native ≥1920×1080 minimum, ≥2560×1440 preferred** so the QHD monitor isn't upscaled (square/portrait/sub-1080 art is rejected even if it color-matches).
- Normalized on install: center-crop to exactly 16:9, scale to ≤3840px wide (1920-wide art upscaled to 2560 via Lanczos), **JPEG quality 92** (~1–2 MB each) to keep the repo lean.

**Source** — the **only** sanctioned repo: `dharmx/walls` (https://github.com/dharmx/walls). Abstract / minimal / poly / geometric, plus an `anime` set. All wallpapers are sourced from here; no other repos.
