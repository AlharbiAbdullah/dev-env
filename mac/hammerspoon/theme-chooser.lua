-- Omarchy-style theme picker: centered fuzzy-search popup listing every theme
-- in ~/.config/themes with a live palette swatch, Enter applies via the
-- switcher. Invoked from aerospace with `hs -c "themeChooser()"`.

local THEMES_DIR = os.getenv("HOME") .. "/.config/themes"
local SWITCHER = os.getenv("HOME") .. "/.local/bin/theme"

local function listThemes()
  local names = {}
  for entry in hs.fs.dir(THEMES_DIR) do
    if entry ~= "." and entry ~= ".." and not entry:match("^[_.]") then
      local lua = THEMES_DIR .. "/" .. entry .. "/theme.lua"
      if hs.fs.attributes(lua, "mode") == "file" then
        names[#names + 1] = entry
      end
    end
  end
  table.sort(names)
  return names
end

local function currentTheme()
  local target = hs.execute("readlink " .. THEMES_DIR .. "/current.lua")
  return target and target:match("([^/]+)/theme%.lua") or nil
end

-- 5-square palette strip: background, then red/green/yellow/blue accents.
local function swatch(name)
  local ok, theme = pcall(dofile, THEMES_DIR .. "/" .. name .. "/theme.lua")
  if not ok or type(theme) ~= "table" or type(theme.colors) ~= "table" then
    return nil
  end
  local c = theme.colors
  local cells = { c.background }
  for _, i in ipairs({ 2, 3, 4, 5 }) do
    cells[#cells + 1] = (c.ansi or {})[i]
  end
  local size, pad = 22, 2
  local canvas = hs.canvas.new({
    x = 0, y = 0,
    w = #cells * (size + pad) - pad, h = size,
  })
  for i, hex in ipairs(cells) do
    canvas[#canvas + 1] = {
      type = "rectangle",
      action = "fill",
      fillColor = { hex = hex or "#000000" },
      roundedRectRadii = { xRadius = 4, yRadius = 4 },
      frame = { x = (i - 1) * (size + pad), y = 0, w = size, h = size },
    }
  end
  local image = canvas:imageFromCanvas()
  canvas:delete()
  return image
end

-- Wallpaper picker for the CURRENT theme: one row per image with a real
-- thumbnail, Enter applies via `theme wallpaper set <path>`.
function wallpaperChooser()
  local current = currentTheme()
  if not current then return end

  local dir = THEMES_DIR .. "/" .. current .. "/wallpapers"
  if hs.fs.attributes(dir, "mode") ~= "directory" then return end

  local activePath = hs.execute(
    "cat " .. os.getenv("HOME") .. "/.cache/theme/" .. current .. ".wallpaper 2>/dev/null"
  ):gsub("%s+$", "")

  local files = {}
  for entry in hs.fs.dir(dir) do
    if entry:match("%.png$") or entry:match("%.jpe?g$") then
      files[#files + 1] = entry
    end
  end
  table.sort(files)

  local choices = {}
  for _, entry in ipairs(files) do
    local path = dir .. "/" .. entry
    local thumb = hs.image.imageFromPath(path)
    if thumb then thumb = thumb:setSize({ w = 64, h = 36 }) end
    choices[#choices + 1] = {
      text = entry:gsub("%.%w+$", ""),
      subText = path == activePath and "current" or nil,
      image = thumb,
      path = path,
    }
  end
  if #choices == 0 then return end

  local chooser = hs.chooser.new(function(choice)
    if choice then
      hs.task.new(SWITCHER, nil, { "wallpaper", "set", choice.path }):start()
    end
  end)
  chooser:choices(choices)
  chooser:rows(math.min(#choices, 10))
  chooser:placeholderText("wallpaper (" .. current .. ")")
  chooser:searchSubText(false)
  chooser:show()
end

function themeChooser()
  local current = currentTheme()
  local choices = {}
  for _, name in ipairs(listThemes()) do
    choices[#choices + 1] = {
      text = name,
      subText = name == current and "current" or nil,
      image = swatch(name),
    }
  end

  local chooser = hs.chooser.new(function(choice)
    if choice then
      hs.task.new(SWITCHER, nil, { choice.text }):start()
    end
  end)
  chooser:choices(choices)
  chooser:rows(math.min(#choices, 12))
  chooser:placeholderText("theme")
  chooser:searchSubText(false)
  chooser:show()
end
