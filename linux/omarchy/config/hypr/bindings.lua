-- Personal bindings carried over from the Ubuntu box. Omarchy defaults stay
-- unless unbound here. See everything with: omarchy menu keybindings --print

local bin = os.getenv("HOME") .. "/.local/bin/"

-- Launcher on SUPER+SPACE (Spotlight habit); root menu moves to SUPER+ALT+SPACE.
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + ALT + SPACE")
o.bind("SUPER + SPACE", "Apps", "omarchy-menu toggle apps")
o.bind("SUPER + ALT + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Apps
o.bind("SUPER + N", "New window of focused app", bin .. "new-window")
o.bind("SUPER + B", "Chrome", { launch = "google-chrome-stable" })
hl.unbind("SUPER + O")
o.bind("SUPER + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })

-- Windows
hl.unbind("SUPER + SHIFT + SPACE")
o.bind("SUPER + SHIFT + SPACE", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + SHIFT + CTRL + B", "Toggle top bar", "omarchy-toggle-bar")

-- Focus mode (float + center + dim the rest), SUPER+-/= widen/narrow.
o.bind("SUPER + H", "Focus mode", bin .. "focus-mode")
hl.unbind("SUPER + code:20")
hl.unbind("SUPER + code:21")
o.bind("SUPER + code:20", "Narrow focused window", 'hyprctl --batch "dispatch resizeactive -100 0; dispatch centerwindow"', { repeating = true })
o.bind("SUPER + code:21", "Widen focused window", 'hyprctl --batch "dispatch resizeactive 100 0; dispatch centerwindow"', { repeating = true })

-- Layout (ALT family)
o.bind("ALT + SLASH", "Toggle split", hl.dsp.layout("togglesplit"))
o.bind("ALT + comma", "Toggle group", hl.dsp.group.toggle())
o.bind("ALT + code:20", "Shrink width", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
o.bind("ALT + code:21", "Grow width", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
o.bind("ALT + SHIFT + code:20", "Shrink height", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
o.bind("ALT + SHIFT + code:21", "Grow height", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

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
hl.unbind("SUPER + L")
o.bind("SUPER + L", "Lock", "omarchy-system-lock")
