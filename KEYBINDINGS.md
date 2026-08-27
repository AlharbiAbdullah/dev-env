# Keybindings: one map for Mac and Linux

Decided 2026-08-27 (decision log: `helm/05-projects/kitchen/omarchy-migration/keybindings-unify.md`).

Rule: **Super or Ctrl only. Shift allowed. No Alt.** Super = Cmd on Mac.

Where each key lives: Mac = `mac/.aerospace.toml` + `mac/hammerspoon/init.lua` + macOS defaults. Linux = `linux/omarchy/config/hypr/bindings.lua` + Omarchy defaults + `config/xremap/config.yml` + `config/ghostty/config`.

## Workspaces

| Key | Action | Mac | Linux |
|---|---|---|---|
| Super+1..9, 0 | go to workspace (0 = 10) | AeroSpace | Omarchy |
| Super+Shift+1..0 | move window there and follow | AeroSpace `--focus-follows-window` | Omarchy |
| Super+Ctrl+Tab | back to the previous workspace | AeroSpace | Omarchy |
| Super+wheel | scroll workspaces | . | Omarchy |

## Windows

| Key | Action | Mac | Linux |
|---|---|---|---|
| Super+arrows | focus left/right/up/down | AeroSpace | Omarchy |
| Super+Shift+arrows | move/swap window | AeroSpace | Omarchy |
| Super+Tab / Super+Shift+Tab | next / previous window | macOS app switcher | bindings.lua |
| Super+W | close window | AeroSpace | Omarchy |
| Super+F | fullscreen | AeroSpace | Omarchy |
| Super+Ctrl+F | tiled fullscreen (keeps bar/gaps) | . | Omarchy |
| Super+Shift+Space | toggle floating | AeroSpace | bindings.lua |
| Super+H | focus mode: float 62% x 92%, centred (+ dim others on Linux) | Hammerspoon `focusMode()` | `focus-mode` script |
| Super+J | toggle split direction | AeroSpace | Omarchy |
| Super+G | toggle group / accordion | AeroSpace | Omarchy |
| Super+- / Super+= | width -100 / +100 | AeroSpace | bindings.lua (`focus-mode resize`) |
| Super+Shift+- / = | height -100 / +100 | AeroSpace | Omarchy |
| Super+Ctrl+- / = | width -25 / +25 | AeroSpace | bindings.lua |
| Super+Shift+Ctrl+B | hide the bar (Linux) / menu bar (Mac) | `menu-toggle` | `omarchy-toggle-bar` |
| Super+P / Super+S / Super+Backspace | pseudo / scratchpad / transparency | . | Omarchy |

## Apps and menus

| Key | Action | Mac | Linux |
|---|---|---|---|
| Super+Space | app launcher | Raycast | `omarchy-menu toggle apps` |
| Super+Ctrl+Space | Omarchy root menu | . | bindings.lua |
| Super+Enter | terminal | iTerm2 window | Ghostty |
| Super+N | new window of the focused app | `new-window` | `new-window` |
| Super+B | Chrome | AeroSpace | bindings.lua |
| Super+O | Obsidian | AeroSpace | bindings.lua |
| Super+Shift+F / Super+Shift+N | file manager / editor | . | Omarchy |
| Super+K | keybindings cheat sheet | . | Omarchy |
| Super+Esc | system menu | . | Omarchy |
| Super+Ctrl+T / Super+Ctrl+Shift+T | theme menu / next theme | Hammerspoon + `theme` | bindings.lua |
| Super+Ctrl+W / Super+Ctrl+Shift+W | wallpaper menu / next | Hammerspoon + `theme` | bindings.lua |

## Mac reflexes inside apps

| Key | Action | Mac | Linux |
|---|---|---|---|
| Super+C / V / X / A / Z / Shift+Z | clipboard, select all, undo, redo | macOS | xremap (GUI apps) / Ghostty binds (terminal) / Cursor keybindings.json (its terminal) |
| Super+R / Super+Shift+R | reload / hard reload | macOS | xremap |
| Super+L | address bar | macOS | xremap |
| Super+Q | quit app | macOS | xremap |
| Ctrl+3 / Ctrl+4 | screenshot full / region to clipboard | macOS hotkeys 29/31 | bindings.lua (grim) |

### How Super+C reaches each app on Linux (one rule, three carriers)

| App | Carrier | What the app receives | Notes |
|---|---|---|---|
| Chrome, Obsidian | xremap (evdev, GUI classes only) | Ctrl+C / Ctrl+V / Ctrl+A / Ctrl+Z | plain app defaults |
| Cursor editor | xremap | Ctrl+C / V / A / Z | app defaults |
| Cursor terminal | xremap + `Cursor/User/keybindings.json` | Ctrl+C copies when text is selected, else interrupt; Ctrl+V pastes | same feel as Cmd+C/V in the Mac Cursor terminal |
| Ghostty (shell, tmux) | Ghostty `performable:super+c`, `super+v`, `super+a` | raw Super key | drag = Ghostty highlight (tmux mouse is off, stock) |
| Claude Code (fullscreen) | Ghostty passes Super+C through when it has no selection | Cmd+C -> `selection:copy` (Claude Code's own drag-select) | Ghostty reports Super via the Kitty protocol |

Omarchy's "universal" Super+C/V/X compositor binds are unbound in `bindings.lua`: they replay Ctrl+Insert/Shift+Insert into terminals and starve Ghostty's performable bind and Claude Code.

## System

| Key | Action | Mac | Linux |
|---|---|---|---|
| Super+Ctrl+L | lock | Hammerspoon | Omarchy |
| Ctrl+Space | keyboard layout us/ara | macOS | `input.lua` `grp:ctrl_space_toggle` |
| Super+Ctrl+R | reload Hyprland | (auto-reload) | bindings.lua |
| Print / Super+Print / Super+Ctrl+Print | Omarchy capture / colour picker / OCR | . | Omarchy |
| Ctrl+B | tmux prefix (stock tmux, default binds) | stock | stock (theme + status only in tmux.conf) |

Omarchy's own Alt-based extras (group moves, scratchpad send, maximize, precise volume) stay bound on Linux by decision: never pressed, never collide.

## Known losses (accepted)

- Super+F is fullscreen, so in-app Find is Ctrl+F (Linux) and gone on Mac.
- Super+W closes the whole window; close a tab with Ctrl+W (Linux) or the mouse (Mac).
- Super+B / Super+O / Super+- / Super+= override Bold / Open / browser zoom on Mac.
- Ctrl+Space is the layout toggle, so editor autocomplete on Ctrl+Space is gone on both.
