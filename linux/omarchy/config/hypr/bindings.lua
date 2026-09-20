-- Personal bindings carried over from the Ubuntu box. Omarchy defaults stay
-- unless unbound here. See everything with: omarchy menu keybindings --print

local bin = os.getenv("HOME") .. "/.local/bin/"

-- Unified map (Mac + Linux, decided 2026-08-27, amended 2026-09-11): Super or
-- Ctrl for the system, Shift ok; ALT/OPTION is reserved for launching apps.
-- Full table: helm/05-projects/completed/omarchy-migration/keybindings-unify.md
-- Launcher on SUPER+SPACE (Spotlight habit); root menu on SUPER+CTRL+SPACE
-- (that was Omarchy's duplicate background switcher).
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + ALT + SPACE")
hl.unbind("SUPER + CTRL + SPACE")
o.bind("SUPER + SPACE", "Apps", "omarchy-menu toggle apps")
o.bind("SUPER + CTRL + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Apps
-- One modifier for "launch an app" (2026-09-11): ALT on Linux is OPTION on the
-- Mac, so the same letter reaches the same app on both machines. Omarchy's own
-- preinstalled-app binds stay off (hyprland.lua sets
-- omarchy_preinstalled_bindings = false); this block replaces them.
-- NO binding here carries `focus` (2026-09-11). Every press launches. Nothing
-- routes through omarchy-launch-or-focus, so nothing raises an existing window
-- instead of opening one, and there is no match pattern to collide with a
-- window title.
hl.unbind("SUPER + B")
hl.unbind("SUPER + O")
o.bind("ALT + B", "Chrome", { launch = "google-chrome-stable" })
-- Obsidian is the one exception: single-instance, so a second launch hands
-- off to the running copy and Wayland will not let it raise itself. Without
-- the matcher the key does nothing once Obsidian is open.
o.bind("ALT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
-- Herdr: terminal workspace manager for AI coding agents. Omarchy binds it
-- on SUPER+CTRL+RETURN, but that sits inside the preinstalled-bindings block
-- this file turns off, so it gets a launch letter like every other app.
o.bind("ALT + H", "Herdr", { omarchy = "terminal-herdr" })
o.bind("ALT + X", "X", { webapp = "https://x.com/" })
o.bind("ALT + M", "Medium", { webapp = "https://medium.com/" })
o.bind("ALT + S", "Substack", { webapp = "https://substack.com/home" })
o.bind("ALT + R", "Reddit", { webapp = "https://www.reddit.com/" })
o.bind("ALT + W", "WhatsApp", { webapp = "https://web.whatsapp.com/" })
o.bind("ALT + Y", "YouTube", { webapp = "https://youtube.com/" })
o.bind("ALT + G", "GitHub", { webapp = "https://github.com/AlharbiAbdullah" })
o.bind("ALT + E", "Gmail", { webapp = "https://mail.google.com/mail/u/0/" })
o.bind("ALT + D", "Excalidraw", { webapp = "https://excalidraw.com/" })
-- Claude opens straight into an incognito CHAT (2026-09-18): Claude's own
-- ghost-icon mode, logged in, chat not saved. Not Chrome incognito, which
-- drops cookies and forces a login every time.
o.bind("ALT + C", "Claude", { webapp = "https://claude.ai/new?incognito=" })
-- A is for agenda: C went to Claude.
o.bind("ALT + A", "Google Calendar", { webapp = "https://calendar.google.com/" })
-- I for gemInI: G is GitHub.
o.bind("ALT + I", "Gemini", { webapp = "https://gemini.google.com/app" })

-- Web app windows have no address bar, so ALT+N lifts the page showing in the
-- focused one into normal Chrome. The script recovers the URL from Chrome's own
-- history by window title; see its header for why.
o.bind("ALT + N", "Open web app page in Chrome", bin .. "webapp-open-in-chrome")

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
o.bind("SUPER + B", "Toggle top bar", "omarchy-toggle-bar")
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
