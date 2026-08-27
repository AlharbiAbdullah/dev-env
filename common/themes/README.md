# common/themes

18 shared theme definitions, consumed 1:1 by both the macOS and Ubuntu setups.
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

## Wallpapers — the standard (2026-08-12 rollout)

Each theme's `wallpapers/` holds **4** images picked by measured palette match,
kept under their **upstream dharmx filenames** (never renamed, never re-encoded).
The full rule set (17-folder allowlist, landscape-only + width ≥ 1920 filters,
CIELAB scoring, no image reused across themes, cap 3 per source folder per theme)
is the single source of truth in the helm vault:
`03-rai/skills/mac/theme.md`, section 6 (`/mac-theme wallpapers`).

Standing content rules: dark art (stylized, not photographic), **no women or
girls**, `dharmx/walls` is the **only** sanctioned source. Score installed packs
with `python3 common/themes/wallpaper-match.py <theme>` (0–100, CIELAB
nearest-palette distance); treat < 60 as a weak match.

History: the June 2026 `<theme>-N.jpg` set (3 per theme, normalized JPEG) was
superseded by the 2026-08-12 rollout. Do not restore it.
