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

-- Ctrl+C/V/X/A/Z/Shift+Z act as Cmd+C/V/X/A/Z/Shift+Z in GUI apps (Linux habit,
-- decided 2026-09-08: Ctrl on both machines). Keycodes, not names, so the Arabic
-- layout remaps the same physical keys. Skipped in terminals (Ctrl+C must stay
-- the interrupt) and in Cursor/Antigravity (they carry their own Ctrl set in
-- keybindings.json, guarded for the integrated terminal).
local CTRL_TO_CMD_KEYCODES = { [8] = "c", [9] = "v", [7] = "x", [0] = "a", [6] = "z" }
local CTRL_TO_CMD_SKIP = {
  ["com.googlecode.iterm2"] = true,
  ["com.apple.Terminal"] = true,
  ["com.mitchellh.ghostty"] = true,
  ["com.todesktop.230313mzl4w4u92"] = true, -- Cursor
  ["com.google.antigravity-ide"] = true,
}
ctrlToCmdTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp }, function(e)
  local f = e:getFlags()
  if not f.ctrl or f.cmd or f.alt or f.fn then return false end
  if not CTRL_TO_CMD_KEYCODES[e:getKeyCode()] then return false end
  local app = hs.application.frontmostApplication()
  if app and CTRL_TO_CMD_SKIP[app:bundleID()] then return false end
  e:setFlags({ cmd = true, shift = f.shift or nil })
  return false
end)
ctrlToCmdTap:start()

-- Reload on config change
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
  for _, f in ipairs(files) do
    if f:sub(-4) == ".lua" then hs.reload(); return end
  end
end):start()
