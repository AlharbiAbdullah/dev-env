-- us + Arabic, Alt+Shift toggles (same as the Ubuntu box). Caps stays the
-- Omarchy compose key. Fast repeat.
hl.config({
  input = {
    kb_layout = "us,ara",
    kb_options = "compose:caps,shift:both_capslock_cancel,grp:alt_shift_toggle",
    follow_mouse = 1,
    -- MX Master 3 free-spin wheel scrolls far too fast at Hyprland's default
    -- of 1.0 (same complaint as the Mac, where LinearMouse sits at 0.125).
    -- Mice only: the touchpad keeps Omarchy's own 0.4.
    scroll_factor = 0.25,
    repeat_rate = 50,
    repeat_delay = 200,
  },
})
