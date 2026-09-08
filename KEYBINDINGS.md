# Keybindings: one map for Mac and Linux

Decided 2026-08-27, revised 2026-09-08 (decision log: `helm/05-projects/completed/omarchy-migration/keybindings-unify.md`).

Rule: **Super or Ctrl only. Shift allowed. No Alt.** Super = Cmd on Mac. Inside apps, clipboard and undo are **Ctrl** on both machines; Super is for the window manager and a few app chords (T, R, L, Q).

Where each key lives: Mac = `mac/.aerospace.toml` + `mac/hammerspoon/init.lua` (lock, focus mode, Ctrl-to-Cmd remap) + `mac/cursor/keybindings.json` + `mac/.tmux.conf` (deployed by `setup.sh`) + macOS defaults. Linux = `linux/omarchy/config/hypr/bindings.lua` + Omarchy defaults + `config/xremap/config.yml` + `config/ghostty/config` + `config/tmux/tmux.conf` + `config/Cursor/User/keybindings.json`. Both: `common/bin/keybindings-menu` (Super+K sheet).

## Workspaces

| Key | Action | Mac | Linux |
|---|---|---|---|
| Super+1..9, 0 | go to workspace (0 = 10) | AeroSpace | Omarchy |
| Super+Shift+1..0 | move window there and follow | AeroSpace `--focus-follows-window` | Omarchy |
| Super+Ctrl+Tab | previous workspace | AeroSpace | Omarchy |
| Super+wheel | scroll workspaces | . | Omarchy |

## Windows

| Key | Action | Mac | Linux |
|---|---|---|---|
| Super+arrows | focus left/right/up/down | AeroSpace | Omarchy |
| Super+Shift+arrows | swap left/right, move up/down | AeroSpace `move` | Omarchy swap + bindings.lua `move` |
| Super+Tab / Super+Shift+Tab | next / previous window | macOS app switcher | bindings.lua |
| Super+W | close window | AeroSpace | Omarchy |
| Super+F | fullscreen | AeroSpace | Omarchy |
| Super+Ctrl+F | tiled fullscreen | . | Omarchy |
| Super+Shift+Space | toggle floating | AeroSpace | bindings.lua |
| Super+H | focus mode (float, centre, dim) | Hammerspoon `focusMode()` | `focus-mode` script |
| Super+J | toggle split direction | AeroSpace | Omarchy |
| Super+G | toggle group / accordion | AeroSpace | Omarchy |
| Super+- / Super+= | width -100 / +100 | AeroSpace | bindings.lua (`focus-mode resize`) |
| Super+Shift+- / = | height -100 / +100 | AeroSpace | Omarchy |
| Super+Ctrl+- / = | width -25 / +25 | AeroSpace | bindings.lua |
| Super+Shift+Ctrl+B | toggle the bar | `menu-toggle` | `omarchy-toggle-bar` |
| Super+P / Super+S / Super+Backspace | pseudo / scratchpad / transparency | . | Omarchy |

## Apps and menus

| Key | Action | Mac | Linux |
|---|---|---|---|
| Super+Space | app launcher | Raycast | `omarchy-menu toggle apps` |
| Super+Ctrl+Space | Omarchy root menu | . | bindings.lua |
| Super+Enter | terminal | iTerm2 window | Ghostty |
| Super+N | new window of app | `new-window` | `new-window` |
| Super+B | Chrome | AeroSpace | bindings.lua |
| Super+O | Obsidian | AeroSpace | bindings.lua |
| Super+Shift+F / Super+Shift+N | file manager / editor | . | Omarchy |
| Super+K | this cheat sheet | AeroSpace `keybindings-menu` (iTerm2 window) | bindings.lua `keybindings-menu` |
| Super+Esc | system menu | . | Omarchy |
| Super+Ctrl+T / Super+Ctrl+Shift+T | theme menu / next theme | Hammerspoon + `theme` | bindings.lua |
| Super+Ctrl+W / Super+Ctrl+Shift+W | wallpaper menu / next | Hammerspoon + `theme` | bindings.lua |

## Inside apps

| Key | Action | Mac | Linux |
|---|---|---|---|
| Ctrl+C / V / X / A / Z / Shift+Z | clipboard, select all, undo, redo | Hammerspoon rewrites Ctrl to Cmd in GUI apps; Cursor keybindings.json; terminals native | stock |
| Super+T | new tab (Chrome, Obsidian, terminal); new untitled file in Cursor | macOS + Cursor keybindings.json `cmd+t` | xremap to Ctrl+T; Ghostty `super+t`; Cursor `meta+t` |
| Super+R / Super+Shift+R | reload / hard reload | macOS | xremap |
| Super+L | address bar | macOS | xremap |
| Super+Q | quit app | macOS | xremap |
| Ctrl+3 / Ctrl+4 | screenshot full / region to clipboard | macOS hotkeys 29/31 | bindings.lua (grim) |

### How Ctrl+C reaches each app (2026-09-08: Ctrl on both, Linux is the model)

| App | Mac | Linux |
|---|---|---|
| Chrome, Obsidian, other GUI apps | Hammerspoon eventtap turns Ctrl+C/V/X/A/Z/Shift+Z into Cmd+... (by keycode, so the Arabic layout works too). Cmd+C still works natively | app default |
| Cursor editor | `keybindings.json` Ctrl set; Hammerspoon skips Cursor and Antigravity | app default |
| Cursor terminal | Ctrl+C copies when text is selected, else interrupt; Ctrl+V pastes | same two rules |
| iTerm2 / Ghostty (shell, tmux) | Ctrl+C is the interrupt; Hammerspoon skips terminals. Copy = mouse drag (tmux copy-pipe to pbcopy) or Cmd+C | Ctrl+C is the interrupt; drag copies via wl-copy; Ghostty keeps `performable:super+c`, `super+v`, `super+a` |
| Claude Code (fullscreen) | Cmd+C copies a selection through iTerm2 | `super+c` -> `selection:copy`, `super+z` -> `chat:undo` (`~/.claude/keybindings.json`) |

Omarchy's "universal" Super+C/V/X compositor binds stay unbound in `bindings.lua`: they replay Ctrl+Insert/Shift+Insert into terminals and starve Ghostty's performable bind and Claude Code. Omarchy's Super+T (float toggle) is unbound too; Super+Shift+Space does that.

## Cursor

| Key | Action | Mac | Linux |
|---|---|---|---|
| Ctrl+P | quick open files | keybindings.json | default |
| Ctrl+Shift+P | command palette | keybindings.json | default |
| Ctrl+G | go to line | default | default |
| Ctrl+Shift+O | symbols in file | keybindings.json | default |
| Ctrl+Tab / Ctrl+Shift+Tab | cycle editor tabs | default | default |
| Ctrl+W | close tab | keybindings.json | default |
| Ctrl+Shift+T | reopen closed tab | keybindings.json | default |
| Super+T | new untitled file (the editor's "new tab") | keybindings.json `cmd+t` | keybindings.json `meta+t` (xremap leaves Super+T raw for Cursor) |
| Ctrl+F / Ctrl+H | find / replace in file | keybindings.json | default |
| Ctrl+Shift+F / Ctrl+Shift+H | find / replace across files | keybindings.json | default |
| Ctrl+D | select next occurrence | keybindings.json | default |
| Ctrl+Shift+L | select all occurrences | keybindings.json | default |
| Ctrl+/ | toggle comment | keybindings.json | default |
| Ctrl+Shift+K | delete line | keybindings.json | default |
| Ctrl+[ / Ctrl+] | outdent / indent | keybindings.json | default |
| Ctrl+X / Ctrl+C | cut / copy line (no selection) | keybindings.json | default |
| Ctrl+. | quick fix | keybindings.json | default |
| Ctrl+E | toggle sidebar | keybindings.json | keybindings.json |
| Ctrl+B | toggle sidebar (stock on Linux) | keybindings.json | default |
| Ctrl+T | toggle terminal | keybindings.json | keybindings.json |
| Ctrl+` | toggle terminal (stock) | default | default |
| Ctrl+J | toggle bottom panel | keybindings.json | default |
| Ctrl+\ | split editor | keybindings.json | default |
| Ctrl+L | AI chat pane | keybindings.json `aichat.newchataction` | default |
| Ctrl+K | inline AI edit | keybindings.json `aipopup.action.modal.generate` | default |
| Ctrl+I | AI agent / composer | keybindings.json `composer.startComposerPrompt` | default |
| Ctrl+Enter | run current file | keybindings.json | keybindings.json |
| Ctrl+C / Ctrl+V in its terminal | copy selection / paste | keybindings.json | keybindings.json |
| Ctrl+= / Ctrl+- / Ctrl+Numpad0 | zoom in / out / reset | keybindings.json | default |

On Linux most of the Ctrl set is Cursor's stock keymap; on the Mac stock is Cmd, so the whole set is carried by `mac/cursor/keybindings.json` (Cmd defaults stay). The word-wise Ctrl+arrows / Ctrl+Backspace / Ctrl+Delete are in the Mac file too, matching Linux editing feel.

Not listed by decision: Ctrl+Space autocomplete (layout toggle owns it) and Ctrl+3 / Ctrl+4 editor-group focus (screenshot binds own them). Both accepted losses.

## Terminal (Ghostty + tmux)

One tmux body on both machines (`mac/.tmux.conf`, `linux/omarchy/config/tmux/tmux.conf`); only the clipboard command differs (pbcopy / wl-copy). Linux loads exactly one user file, `~/.config/tmux/tmux.conf` (the old `~/.tmux.conf` was removed 2026-09-08).

| Key | Action | Mac | Linux |
|---|---|---|---|
| Ctrl+B | tmux prefix (stock) | tmux.conf | tmux.conf |
| Ctrl+B then pipe / minus | tmux split horizontal / vertical | tmux.conf | tmux.conf |
| Mouse drag in tmux | copy to system clipboard (mouse on) | tmux.conf | tmux.conf |
| Shift+Enter | newline (Claude Code) | tmux passthrough | Ghostty config + tmux passthrough |
| Super+T | new terminal tab | iTerm2 | Ghostty `super+t` |

## System

| Key | Action | Mac | Linux |
|---|---|---|---|
| Super+Ctrl+L | lock | Hammerspoon | Omarchy |
| Ctrl+Space | keyboard layout us/ara | macOS | `input.lua` `grp:ctrl_space_toggle` |
| Super+Ctrl+R | reload Hyprland | (auto-reload) | bindings.lua |
| Print / Super+Print / Super+Ctrl+Print | Omarchy capture / colour picker / OCR | . | Omarchy |

Omarchy's own Alt-based extras (group moves, scratchpad send, maximize, precise volume) stay bound on Linux by decision: never pressed, never collide.

## Mouse

Click to focus on both machines (macOS native; Linux `follow_mouse = 2` in `input.lua`, 2026-08-27). Hovering never moves keyboard focus; scrolling still goes to the window under the cursor.

## Known losses (accepted)

- Super+K is the cheat sheet on both, so Cmd+K inside Mac apps is gone (Cursor inline edit = Ctrl+K, Obsidian link, Chrome search). Linux already lived with this.
- Mac Mission Control "move a space left/right" (Ctrl+Left/Right, hotkeys 79/81) is disabled so Cursor's word-wise Ctrl+arrows reach the editor.
- Super+F is fullscreen, so in-app Find is Ctrl+F (Linux) and gone on Mac.
- Super+W closes the whole window; close a tab with Ctrl+W (Linux) or the mouse (Mac).
- Super+B / Super+O / Super+- / Super+= override Bold / Open / browser zoom on Mac.
- Ctrl+Space is the layout toggle, so editor autocomplete on Ctrl+Space is gone on both.
