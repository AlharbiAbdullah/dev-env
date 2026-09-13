# common/wallpaper

Wallpaper rules and tooling. The images themselves are not kept in the repo;
they live per machine in `~/.config/themes/<name>/wallpapers/`.

## Wallpapers — the standard (2026-08-12 rollout)

Each theme's `wallpapers/` holds **4** images picked by measured palette match,
kept under their **upstream dharmx filenames** (never renamed, never re-encoded).
The full rule set (17-folder allowlist, landscape-only + width ≥ 1920 filters,
CIELAB scoring, no image reused across themes, cap 3 per source folder per theme)
is the single source of truth in the helm vault:
`03-rai/skills/mac/theme.md`, section 6 (`/mac-theme wallpapers`).

Standing content rules: dark art (stylized, not photographic), **no women or
girls**, `dharmx/walls` is the **only** sanctioned source. Score installed packs
with `python3 common/wallpaper/wallpaper-match.py <theme>` (0–100, CIELAB
nearest-palette distance); treat < 60 as a weak match.

History: the June 2026 `<theme>-N.jpg` set (3 per theme, normalized JPEG) was
superseded by the 2026-08-12 rollout. Do not restore it.

Standing exception (Abdullah, 2026-09-01): `cannonbreed-dark-souls-bonfire.png`
("Rest Here Weary Traveler", pixel art by Cannonbreed) is a 5th wallpaper in
EVERY theme on both machines: a full-screen widescreen extension of the original
scene, AI-generated from the original art and finished per screen (Mac 3024x1964,
Linux 2560x1440, so the two machines' copies intentionally differ). Personal
meaning. Never purge, dedup, or count it against the dharmx rules. Derivative of
a living artist's work: desktop use only, never redistribute.
