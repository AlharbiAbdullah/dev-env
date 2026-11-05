-- xremap: Mac-style Super clipboard in GUI apps (unit needs HYPRLAND_INSTANCE_SIGNATURE,
-- which Omarchy imports into the user manager at session start).
hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user restart xremap.service")
  -- 1Password service account token, once per boot: ~/helm/12-system/tools/op/README.md
  hl.exec_cmd("~/helm/12-system/tools/op/login.sh")
end)
