-- Same look as the Ubuntu box: tight gaps, 5px accent border, transparent
-- inactive border, no rounding, blur on (used by focus-mode), instant workspaces.
hl.config({
  general = {
    gaps_in = 2,
    gaps_out = 5,
    border_size = 5,
    col = { inactive_border = "rgba(00000000)" },
    layout = "dwindle",
  },
  decoration = {
    rounding = 0,
    blur = { enabled = true, size = 6, passes = 3, new_optimizations = true, ignore_opacity = true },
  },
  dwindle = { preserve_split = true },
})

hl.animation({ leaf = "workspaces", enabled = false })
hl.animation({ leaf = "specialWorkspace", enabled = false })
