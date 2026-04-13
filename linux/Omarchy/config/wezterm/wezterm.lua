local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font("NotoSansM Nerd Font", { weight = "Bold" })
config.font_size = 12

-- Window
config.window_decorations = "NONE"
config.window_padding = { left = 14, right = 14, top = 14, bottom = 14 }
config.window_close_confirmation = "NeverPrompt"
config.enable_tab_bar = false

-- Cursor
config.default_cursor_style = "SteadyBlock"

-- Scrollback
config.scrollback_lines = 10000

-- Keybindings
config.keys = {
  { key = "Insert", mods = "SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
  { key = "Insert", mods = "CTRL", action = wezterm.action.CopyTo("Clipboard") },
}

-- BiDi / Arabic support
config.bidi_enabled = true
config.bidi_direction = "AutoLeftToRight"

-- Load theme colors from omarchy
local theme_file = os.getenv("HOME") .. "/.config/omarchy/current/theme/colors.toml"
local function load_colors()
  local f = io.open(theme_file, "r")
  if not f then return nil end
  local colors = {}
  for line in f:lines() do
    local key, val = line:match('^(%S+)%s*=%s*"(#%x+)"')
    if key and val then
      colors[key] = val
    end
  end
  f:close()
  return colors
end

local c = load_colors()
if c then
  config.colors = {
    foreground = c.foreground,
    background = c.background,
    cursor_bg = c.cursor,
    cursor_fg = c.background,
    selection_fg = c.selection_foreground,
    selection_bg = c.selection_background,
    ansi = {
      c.color0, c.color1, c.color2, c.color3,
      c.color4, c.color5, c.color6, c.color7,
    },
    brights = {
      c.color8, c.color9, c.color10, c.color11,
      c.color12, c.color13, c.color14, c.color15,
    },
  }
end

return config
