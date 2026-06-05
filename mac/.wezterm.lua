local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- BiDi support for Arabic RTL
config.bidi_enabled = true
config.bidi_direction = "AutoLeftToRight"

-- Font
config.font = wezterm.font_with_fallback({
    { family = "NotoSansM Nerd Font", weight = "Bold", harfbuzz_features = { "liga=0" } },
    { family = "Cairo", weight = "Bold" },
    "Apple Color Emoji",
})
config.font_size = 16.0

-- Load current theme (~/.config/themes/current.lua -> symlink)
local theme_path = os.getenv("HOME") .. "/.config/themes/current.lua"
local ok, theme = pcall(dofile, theme_path)
if ok and theme and theme.colors then
    config.colors = theme.colors
end

-- Keybindings
config.keys = {
    { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },
    -- Let macOS handle screenshot shortcuts
    { key = "3", mods = "CMD|SHIFT", action = wezterm.action.DisableDefaultAssignment },
    { key = "4", mods = "CMD|SHIFT", action = wezterm.action.DisableDefaultAssignment },
    { key = "5", mods = "CMD|SHIFT", action = wezterm.action.DisableDefaultAssignment },
}

config.window_close_confirmation = "NeverPrompt"

return config
