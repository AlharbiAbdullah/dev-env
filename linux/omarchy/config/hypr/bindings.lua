-- Personal bindings carried over from the Ubuntu box. Omarchy defaults stay
-- unless unbound here. See everything with: omarchy menu keybindings --print

local bin = os.getenv("HOME") .. "/.local/bin/"

-- Unified map (Mac + Linux, decided 2026-08-27): Super or Ctrl only, Shift ok,
-- no Alt. Full table: helm/05-projects/kitchen/omarchy-migration/keybindings-unify.md
-- Launcher on SUPER+SPACE (Spotlight habit); root menu on SUPER+CTRL+SPACE
-- (that was Omarchy's duplicate background switcher).
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + ALT + SPACE")
hl.unbind("SUPER + CTRL + SPACE")
o.bind("SUPER + SPACE", "Apps", "omarchy-menu toggle apps")
o.bind("SUPER + CTRL + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Apps
o.bind("SUPER + N", "New window of focused app", bin .. "new-window")
o.bind("SUPER + B", "Chrome", { launch = "google-chrome-stable" })
hl.unbind("SUPER + O")
o.bind("SUPER + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })

-- Clipboard: Omarchy's "universal" SUPER+C/V/X binds are OFF. They intercept the
-- key at the compositor and replay CTRL+Insert/Shift+Insert, which breaks the
-- terminal path: Ghostty's own `performable:super+c` (copies a terminal
-- selection, otherwise passes SUPER+C to the app) and Claude Code's fullscreen
-- selection copy (Cmd+C) never get the key. GUI apps get SUPER->CTRL from
-- xremap, terminals get the raw key. One rule: SUPER+C/V/A/X everywhere.
hl.unbind("SUPER + C")
hl.unbind("SUPER + V")
hl.unbind("SUPER + X")

-- Windows
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")
o.bind("SUPER + TAB", "Focus on next window", hl.dsp.window.cycle_next())
o.bind("SUPER + SHIFT + TAB", "Focus on previous window", hl.dsp.window.cycle_next({ next = false }))
o.bind("SUPER + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())
o.bind("SUPER + SHIFT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())
hl.unbind("SUPER + SHIFT + SPACE")
o.bind("SUPER + SHIFT + SPACE", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + SHIFT + CTRL + B", "Toggle top bar", "omarchy-toggle-bar")

-- Focus mode (float + center + dim the rest), SUPER+-/= widen/narrow.
-- Hyprland 0.56 Lua: `hyprctl dispatch` takes Lua dispatchers, not the old
-- string form. The script wraps the new syntax (fixed 2026-08-27).
o.bind("SUPER + H", "Focus mode", bin .. "focus-mode")
hl.unbind("SUPER + code:20")
hl.unbind("SUPER + code:21")
o.bind("SUPER + code:20", "Narrow focused window", bin .. "focus-mode resize -100", { repeating = true })
o.bind("SUPER + code:21", "Widen focused window", bin .. "focus-mode resize 100", { repeating = true })

-- Layout: split = SUPER+J, group = SUPER+G, height = SUPER+SHIFT+-/= (all Omarchy
-- defaults). Fine width step on SUPER+CTRL+-/= (Omarchy's "a lot" slot, now 25px).
hl.unbind("SUPER + CTRL + code:20")
hl.unbind("SUPER + CTRL + code:21")
o.bind("SUPER + CTRL + code:20", "Narrow a little", hl.dsp.window.resize({ x = -25, y = 0, relative = true }), { repeating = true })
o.bind("SUPER + CTRL + code:21", "Widen a little", hl.dsp.window.resize({ x = 25, y = 0, relative = true }), { repeating = true })

-- Theme / wallpaper (Omarchy owns both now)
hl.unbind("SUPER + CTRL + T")
hl.unbind("SUPER + CTRL + W")
o.bind("SUPER + CTRL + T", "Theme menu", "omarchy-menu toggle theme")
o.bind("SUPER + CTRL + W", "Background menu", "omarchy-menu toggle background")
o.bind("SUPER + CTRL + SHIFT + T", "Next theme", bin .. "theme cycle")
o.bind("SUPER + CTRL + SHIFT + W", "Next background", "omarchy-theme-bg-next")

-- Screenshots straight to clipboard (Mac habit); PRINT keeps Omarchy's capture flow.
o.bind("CTRL + code:12", "Screenshot to clipboard", "grim - | wl-copy")
o.bind("CTRL + code:13", "Region screenshot to clipboard", 'grim -g "$(slurp)" - | wl-copy')

-- Brightness over DDC/CI (external monitor, no backlight device).
hl.unbind("XF86MonBrightnessUp")
hl.unbind("XF86MonBrightnessDown")
o.bind("XF86MonBrightnessUp", "Monitor brighter", "ddcutil --noverify setvcp 10 + 10", { locked = true })
o.bind("XF86MonBrightnessDown", "Monitor dimmer", "ddcutil --noverify setvcp 10 - 10", { locked = true })

-- Session
hl.unbind("SUPER + CTRL + R")
o.bind("SUPER + CTRL + R", "Reload Hyprland", "hyprctl reload")
-- SUPER+L is the address bar (xremap -> CTRL+L in GUI apps); lock = SUPER+CTRL+L
-- (Omarchy default). Unbound here so a stray SUPER+L in a terminal does nothing.
hl.unbind("SUPER + L")
