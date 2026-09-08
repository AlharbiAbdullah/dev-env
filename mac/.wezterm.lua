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

-- Blend two "#rrggbb" colors: amount 0 -> c1, 1 -> c2
local function blend(c1, c2, amount)
    local r1, g1, b1 = c1:match("#(%x%x)(%x%x)(%x%x)")
    local r2, g2, b2 = c2:match("#(%x%x)(%x%x)(%x%x)")
    local function mix(a, b)
        a, b = tonumber(a, 16), tonumber(b, 16)
        return math.floor(a + (b - a) * amount + 0.5)
    end
    return string.format("#%02x%02x%02x", mix(r1, r2), mix(g1, g2), mix(b1, b2))
end

if ok and theme and theme.colors then
    config.colors = theme.colors

    -- Tab bar: themes only define terminal colors, so derive the tab bar
    -- from the same palette instead of wezterm's default grey chrome.
    local bg = theme.colors.background
    local fg = theme.colors.foreground
    local surface = blend(bg, fg, 0.15)
    local dim = blend(bg, fg, 0.55)
    config.window_frame = {
        active_titlebar_bg = bg,
        inactive_titlebar_bg = bg,
    }
    config.colors.tab_bar = {
        background = bg,
        inactive_tab_edge = bg,
        active_tab = { bg_color = surface, fg_color = fg },
        inactive_tab = { bg_color = bg, fg_color = dim },
        inactive_tab_hover = { bg_color = surface, fg_color = fg },
        new_tab = { bg_color = bg, fg_color = dim },
        new_tab_hover = { bg_color = surface, fg_color = fg },
    }
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
