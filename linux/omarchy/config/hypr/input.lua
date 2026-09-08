-- us + Arabic, Ctrl+Space toggles (same as the Mac, unified 2026-08-27). Caps stays the
-- Omarchy compose key. Fast repeat.
hl.config({
  input = {
    kb_layout = "us,ara",
    kb_options = "compose:caps,shift:both_capslock_cancel,grp:ctrl_space_toggle",
    -- Mac-style focus: hovering never changes keyboard focus, a click does.
    -- Scroll still goes to the window under the cursor (also Mac behaviour).
    follow_mouse = 2,
    float_switch_override_focus = 0,
    repeat_rate = 50,
    repeat_delay = 200,
  },
})
