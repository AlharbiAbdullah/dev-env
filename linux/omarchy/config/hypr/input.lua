-- us + Arabic, Alt+Shift toggles (same as the Ubuntu box). Caps stays the
-- Omarchy compose key. Fast repeat.
hl.config({
  input = {
    kb_layout = "us,ara",
    kb_options = "compose:caps,shift:both_capslock_cancel,grp:alt_shift_toggle",
    follow_mouse = 1,
    repeat_rate = 50,
    repeat_delay = 200,
  },
})
