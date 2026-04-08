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
    { family = "JetBrains Mono", weight = "Bold", harfbuzz_features = { "liga=0" } },
    { family = "Cairo", weight = "Bold" },
    "Noto Color Emoji",
})
config.font_size = 16.0

-- Gruvbox Dark theme
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

-- Keybindings
config.keys = {
    { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },
}

-- Window state
config.window_close_confirmation = "NeverPrompt"

return config
