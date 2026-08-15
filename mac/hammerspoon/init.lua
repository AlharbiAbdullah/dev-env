-- Minimal Hammerspoon config: expose IPC so `hs -c '...'` works from shell.
-- Used by ~/.local/bin/theme to show a centered on-screen HUD.

hs.ipc.cliInstall()

-- Omarchy-style theme picker popup (bound to cmd-ctrl-t in ~/.aerospace.toml)
require("theme-chooser")

-- Cmd+L -> lock screen
hs.hotkey.bind({"cmd"}, "L", function()
  hs.caffeinate.lockScreen()
end)

-- Reload on config change
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
  for _, f in ipairs(files) do
    if f:sub(-4) == ".lua" then hs.reload(); return end
  end
end):start()
