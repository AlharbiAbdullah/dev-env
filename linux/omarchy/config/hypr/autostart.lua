-- xremap: Mac-style Super clipboard in GUI apps (unit needs HYPRLAND_INSTANCE_SIGNATURE,
-- which Omarchy imports into the user manager at session start).
hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user restart xremap.service")
end)
