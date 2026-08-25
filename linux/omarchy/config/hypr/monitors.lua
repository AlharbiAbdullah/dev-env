-- KTC H27T27, 2560x1440, 100 Hz available. Not a retina display: 1x everywhere.
local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
hl.monitor({ output = "DP-1", mode = "2560x1440@100", position = "0x0", scale = 1 })
