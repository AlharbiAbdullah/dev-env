local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- BiDi support for Arabic RTL
config.bidi_enabled = true
config.bidi_direction = "AutoLeftToRight"

-- Font (from Ghostty)
config.font = wezterm.font_with_fallback({
    { family = "NotoSansM Nerd Font", harfbuzz_features = { "liga=0" } },
    { family = "Cairo", weight = "Bold" },
    "Apple Color Emoji",
})
config.font_size = 16.0

-- Gruvbox Dark theme (from Ghostty)
config.colors = {
    background = "#282828",
    foreground = "#ebdbb2",
    cursor_bg = "#ebdbb2",
    cursor_fg = "#282828",
    selection_bg = "#665c54",
    selection_fg = "#ebdbb2",

    ansi = {
        "#282828", -- black
        "#cc241d", -- red
        "#98971a", -- green
        "#d79921", -- yellow
        "#458588", -- blue
        "#b16286", -- magenta
        "#689d6a", -- cyan
        "#a89984", -- white
    },
    brights = {
        "#928374", -- bright black
        "#fb4934", -- bright red
        "#b8bb26", -- bright green
        "#fabd2f", -- bright yellow
        "#83a598", -- bright blue
        "#d3869b", -- bright magenta
        "#8ec07c", -- bright cyan
        "#ebdbb2", -- bright white
    },
}

-- Keybindings (from Ghostty)
config.keys = {
    { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },
}

-- Window state (from Ghostty: window-save-state = never)
config.window_close_confirmation = "NeverPrompt"

return config
