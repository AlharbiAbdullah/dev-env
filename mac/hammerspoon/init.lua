-- Minimal Hammerspoon config: expose IPC so `hs -c '...'` works from shell.
-- Used by ~/.local/bin/theme to show a centered on-screen HUD.

hs.ipc.cliInstall()

-- Omarchy-style theme picker popup (bound to cmd-ctrl-t in ~/.aerospace.toml)
require("theme-chooser")

-- Cmd+Ctrl+L -> lock screen (unified with Linux 2026-08-27; Cmd+L is the
-- address bar again).
hs.hotkey.bind({"cmd", "ctrl"}, "L", function()
  hs.caffeinate.lockScreen()
end)

-- Focus mode, same as the Linux SUPER+H: float the window at 62% x 92% of the
-- screen, centred; press again to tile it back. Bound to cmd-h in
-- ~/.aerospace.toml via `hs -c "focusMode()"`. (No dimming of the others on
-- macOS; AeroSpace has no inactive-window opacity.)
local AEROSPACE = "/opt/homebrew/bin/aerospace"
local focusModeOn = false
function focusMode()
  local win = hs.window.focusedWindow()
  if not win then return end
  if focusModeOn then
    hs.execute(AEROSPACE .. " layout tiling")
    focusModeOn = false
    return
  end
  hs.execute(AEROSPACE .. " layout floating")
  focusModeOn = true
  hs.timer.doAfter(0.15, function()
    local f = win:screen():frame()
    local w, h = f.w * 0.62, f.h * 0.92
    win:setFrame({ x = f.x + (f.w - w) / 2, y = f.y + (f.h - h) / 2, w = w, h = h })
  end)
end

-- Reload on config change
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
  for _, f in ipairs(files) do
    if f:sub(-4) == ".lua" then hs.reload(); return end
  end
end):start()
