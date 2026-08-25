-- everbloom-noir: everbloom after dark. High-contrast sibling, same bloodline.
-- Custom original theme (not Omarchy-tracked). Derived from everbloom by two
-- moves, not a recolor: (1) the violet field drops from #2a2733 to #17131f, so
-- contrast comes from the FLOOR falling, not the text glaring -- foreground
-- stays a warm bone at 81% brightness, never white; (2) every accent gains
-- saturation and splits into a real ansi/bright pair (everbloom's were
-- identical), so bold text finally reads as bold.
-- fg/bg = 11.6:1 (everbloom: 8.1:1). Every accent clears 7:1 (everbloom: 5.1).
-- Tradeoff, stated: the near-black field costs the bg_lift factor in
-- comfort-score.py (60 vs everbloom's 78). This is the glare-hours theme --
-- bright room, daylight on the panel. everbloom stays the late-night one.
return {
  name = "everbloom-noir",
  border = "0xffd9b3ff",
  macos = "dark",
  source = "original",
  vscode = "Everbloom Noir (generated)",
  cursor = "Everbloom Noir (generated)",
  colors = {
    background = "#17131f",
    foreground = "#dfcbb2",
    cursor_bg = "#d9b3ff",
    cursor_fg = "#17131f",
    selection_bg = "#4c4560",
    selection_fg = "#dfcbb2",
    ansi = {
      "#4c4560", "#ef8085", "#b5c97e", "#e6bb72", "#94a8e2", "#cea5f0", "#8ad2a4", "#dfcbb2",
    },
    brights = {
      "#665d80", "#ff9ba0", "#cbe092", "#ffd489", "#b0c1f7", "#e3c0ff", "#a5eabf", "#eaddc9",
    },
  },
}
