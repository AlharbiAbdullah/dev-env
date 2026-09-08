-- Personal bindings carried over from the Ubuntu box. Omarchy defaults stay
-- unless unbound here. See everything with: omarchy menu keybindings --print

local bin = os.getenv("HOME") .. "/.local/bin/"

-- Unified map (Mac + Linux, decided 2026-08-27): Super or Ctrl only, Shift ok,
-- no Alt. Full table: helm/05-projects/completed/omarchy-migration/keybindings-unify.md
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

-- Clipboard is CTRL+C/V/X/A/Z in GUI apps on both machines (2026-09-08), so
-- Omarchy's "universal" SUPER+C/V/X binds stay OFF: they replay
-- CTRL+Insert/Shift+Insert into terminals and starve Ghostty's own
-- `performable:super+c` and Claude Code's fullscreen selection copy.
hl.unbind("SUPER + C")
hl.unbind("SUPER + V")
hl.unbind("SUPER + X")
-- SUPER+T = new tab everywhere (Mac Cmd+T habit, 2026-09-08): xremap turns it
-- into CTRL+T for GUI apps, Ghostty binds it, Cursor binds meta+t. Omarchy's
-- float toggle on SUPER+T is unbound; SUPER+SHIFT+SPACE already does that.
hl.unbind("SUPER + T")

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
-- SUPER+SHIFT+UP/DOWN: Omarchy's `swap` needs a neighbour above/below, and a
-- two-window workspace is always side by side, so the keys did nothing.
-- `move` re-splits vertically instead (the Ubuntu `movewindow` behaviour, and
-- what AeroSpace `move up/down` does on the Mac). LEFT/RIGHT stay Omarchy's swap.
hl.unbind("SUPER + SHIFT + UP")
hl.unbind("SUPER + SHIFT + DOWN")
o.bind("SUPER + SHIFT + UP", "Move window up", hl.dsp.window.move({ direction = "u" }))
o.bind("SUPER + SHIFT + DOWN", "Move window down", hl.dsp.window.move({ direction = "d" }))

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

-- Keybindings cheat sheet: only the personal map, parsed live from
-- ~/dev-env/KEYBINDINGS.md. Full Omarchy dump stays on
-- `omarchy-menu-keybindings` if ever needed. Dedicated app-id + rules so the
-- floating window is sized for the sheet (the stock 875x600 float is 79 cols,
-- narrower than the rendered boxes).
hl.unbind("SUPER + K")
o.bind("SUPER + K", "Keybindings", bin .. "keybindings-menu")
o.window("org.omarchy.keybindings", { float = true })
o.window("org.omarchy.keybindings", { center = true })
o.window("org.omarchy.keybindings", { size = { 1000, 920 } })

-- Session
hl.unbind("SUPER + CTRL + R")
o.bind("SUPER + CTRL + R", "Reload Hyprland", "hyprctl reload")
-- SUPER+L is the address bar (xremap -> CTRL+L in GUI apps); lock = SUPER+CTRL+L
-- (Omarchy default). Unbound here so a stray SUPER+L in a terminal does nothing.
hl.unbind("SUPER + L")
