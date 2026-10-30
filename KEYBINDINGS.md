# Keybindings: one map for both Omarchy machines

Decided 2026-08-27, revised 2026-09-11 (decision log: `helm/05-projects/completed/omarchy-migration/keybindings-unify.md`).

Rule: **Super or Ctrl for the system, Alt for launching apps. Shift allowed.** Inside apps, clipboard and undo are **Ctrl** on both machines; Super is for the window manager and a few app chords (T, R, L, Q).

Where each key lives: `linux/omarchy/config/hypr/bindings.lua` + Omarchy defaults + `config/xremap/config.yml` + `config/ghostty/config` + `config/tmux/tmux.conf` + `config/{Cursor,Code}/User/keybindings.json`. The Super+K sheet reads this map through `common/bin/keybindings-menu`.

## Workspaces

| Key | Action | Linux |
|---|---|---|
| Super+1..9, 0 | go to workspace (0 = 10) | Omarchy |
| Super+Shift+1..0 | move window there and follow | Omarchy |
| Super+Ctrl+Tab | previous workspace | Omarchy |
| Super+wheel | scroll workspaces | Omarchy |

## Windows

| Key | Action | Linux |
|---|---|---|
| Super+arrows | focus left/right/up/down | Omarchy |
| Super+Shift+arrows | swap left/right, move up/down | Omarchy swap + bindings.lua `move` |
| Super+Tab / Super+Shift+Tab | next / previous window | bindings.lua |
| Super+W | close window | Omarchy |
| Super+F | fullscreen | Omarchy |
| Super+Ctrl+F | tiled fullscreen | Omarchy |
| Super+Shift+Space | toggle floating | bindings.lua |
| Super+H | focus mode (float, centre, dim) | `focus-mode` script |
| Super+J | toggle split direction | Omarchy |
| Super+G | toggle group / accordion | Omarchy |
| Super+- / Super+= | width -100 / +100 | bindings.lua (`focus-mode resize`) |
| Super+Shift+- / = | height -100 / +100 | Omarchy |
| Super+Ctrl+- / = | width -25 / +25 | bindings.lua |
| Super+B | toggle the bar | `omarchy-toggle-bar` |
| Super+P / Super+S / Super+Backspace | pseudo / scratchpad / transparency | Omarchy |

## Apps and menus

| Key | Action | Linux |
|---|---|---|
| Super+Space | app launcher | `omarchy-menu toggle apps` |
| Super+Ctrl+Space | Omarchy root menu | bindings.lua |
| Super+Enter | terminal | Ghostty |
| Super+Shift+F / Super+Shift+N | file manager / editor | Omarchy |
| Super+K | this cheat sheet | bindings.lua `keybindings-menu` |
| Super+Esc | system menu | Omarchy |
| Super+Ctrl+T | theme menu | bindings.lua (Omarchy menu) |
| Super+Ctrl+W / Super+Ctrl+Shift+W | wallpaper menu / next | bindings.lua |

## App launchers (Alt)

One modifier means one thing: Alt launches an app, or raises it if it is already
open. Native apps and web apps share the row so the letter is all you remember.

| Key | App | Kind | Linux |
|---|---|---|---|
| Alt+B | Chrome | native | bindings.lua |
| Alt+H | Herdr | native | bindings.lua |
| Alt+X | X | web app | bindings.lua |
| Alt+M | Medium | web app | bindings.lua |
| Alt+S | Substack | web app | bindings.lua |
| Alt+R | Reddit | web app | bindings.lua |
| Alt+W | WhatsApp | web app | bindings.lua |
| Alt+Y | YouTube | web app | bindings.lua |
| Alt+G | GitHub | web app | bindings.lua |
| Alt+E | Gmail | web app | bindings.lua |
| Alt+D | Excalidraw | web app | bindings.lua |
| Alt+C | Claude | web app (incognito chat) | bindings.lua |
| Alt+A | Google Calendar | web app | bindings.lua |
| Alt+I | Gemini | web app | bindings.lua |
| Alt+N | open the focused web app's page in normal Chrome | script | `common/bin/webapp-open-in-chrome` |

Alt is global, so these win over the terminal. The one real cost is **Alt+B**,
which was readline/ble.sh backward-word in bash. Alt+F still moves forward a word;
Ctrl+Left moves back.

Every press of a web app key opens **another window**: two YouTube windows = Alt+Y twice.
Chrome handles its own windows.

A web app window has no address bar, so **Alt+N** lifts the page it is showing
into normal Chrome, where Ctrl+L works.

## Inside apps

| Key | Action | Linux |
|---|---|---|
| Ctrl+C / V / X / A / Z / Shift+Z | clipboard, select all, undo, redo | stock |
| Super+T | new tab (Chrome, terminal); new untitled file in the editors | xremap to Ctrl+T; Ghostty `super+t`; Cursor and VS Code `meta+t` |
| Super+R / Super+Shift+R | reload / hard reload | xremap |
| Super+L | address bar | xremap |
| Super+Q | quit app | xremap |
| Ctrl+3 / Ctrl+4 | screenshot full / region to clipboard | bindings.lua (grim) |

### How Ctrl+C reaches each app

| App | Linux |
|---|---|
| Chrome, other GUI apps | app default |
| Cursor / VS Code editor | app default |
| Cursor / VS Code terminal | Ctrl+C copies selected text, otherwise interrupts; Ctrl+V pastes |
| Ghostty (shell, tmux) | Ctrl+C is the interrupt; drag copies via wl-copy; Ghostty keeps `performable:super+c`, `super+v`, `super+a` |
| Claude Code (fullscreen) | `super+c` -> `selection:copy`, `super+z` -> `chat:undo` (`~/.claude/keybindings.json`) |

Omarchy's "universal" Super+C/V/X compositor binds stay unbound in `bindings.lua`.
They replay Ctrl+Insert/Shift+Insert into terminals and starve Ghostty's performable bind and Claude Code.
Omarchy's Super+T (float toggle) is unbound too; Super+Shift+Space does that.

## Cursor + VS Code

One keymap for both editors. Every editor key is Ctrl-based: Alt belongs to the app launchers.
The Alt- and F-row stock keys have Ctrl twins and are not listed.
Cursor is a VS Code fork, so this whole set is stock in both.

| Key | Action | Linux |
|---|---|---|
| Ctrl+P | quick open files | default |
| Ctrl+Shift+P | command palette | default |
| Ctrl+G | go to line | default |
| Ctrl+Shift+O | symbols in file | default |
| Ctrl+Tab / Ctrl+Shift+Tab | cycle editor tabs | default |
| Ctrl+W | close tab | default |
| Ctrl+Shift+T | reopen closed tab | default |
| Super+T | new untitled file (the editor's "new tab") | keybindings.json `meta+t` (xremap leaves Super+T raw for both editors) |
| Ctrl+F / Ctrl+H | find / replace in file | default |
| Ctrl+Shift+F / Ctrl+Shift+H | find / replace across files. Ctrl+Shift+F opens a full-width search editor (`search.mode: newEditor`), and pressed again inside it closes the page | default + keybindings.json (close rule) |
| Ctrl+D | select next occurrence | default |
| Ctrl+Shift+L | select all occurrences | default |
| Ctrl+/ | toggle comment | default |
| Ctrl+Shift+K | delete line | default |
| Ctrl+[ / Ctrl+] | outdent / indent | default |
| Ctrl+X / Ctrl+C | cut / copy line (no selection) | default |
| Ctrl+. | quick fix | default |
| Ctrl+E | file tree. VS Code: always the explorer (the Claude view shares the same side bar), and Ctrl+E again closes it. Cursor: toggle sidebar | keybindings.json |
| Ctrl+B | go to definition (F12 also works); Ctrl+Alt+- jumps back | keybindings.json |
| Ctrl+Shift+B | list all usages of the symbol (Shift+F12 also works) | keybindings.json |
| Ctrl+Shift+R | rename symbol across files (F2 also works) | keybindings.json |
| Ctrl+Up / Ctrl+Down | grow / shrink the selection by scope | keybindings.json |
| Ctrl+Shift+Up / Down | move the line or selected block | keybindings.json |
| Ctrl+Alt+Up / Down | add a cursor on the line above / below | keybindings.json |
| Ctrl+Alt+I | a cursor at the end of every selected line | keybindings.json |
| Ctrl+T | toggle terminal | keybindings.json |
| Ctrl+` | toggle terminal (stock) | default |
| Ctrl+J | toggle bottom panel | default |
| Ctrl+\ | split editor | default |
| Ctrl+Alt+Right / Ctrl+Alt+Left | move the current file into the next / previous split (two different files side by side) | default |
| Ctrl+L | AI pane. Cursor: chat. VS Code: Claude Code side bar, and Ctrl+L again closes it | Cursor default; VS Code keybindings.json |
| Ctrl+K | inline AI edit (Cursor only; VS Code keeps the chord prefix) | default |
| Ctrl+I | AI agent / composer (Cursor only) | default |
| Ctrl+Enter | run current file; in a dbt model, preview the query (official dbt extension) | keybindings.json |
| Ctrl+C / Ctrl+V in its terminal | copy selection / paste | keybindings.json |
| Ctrl+= / Ctrl+- / Ctrl+Numpad0 | zoom in / out / reset | default |

Not listed by decision: Ctrl+Space autocomplete (layout toggle owns it) and Ctrl+3 / Ctrl+4 editor-group focus (screenshot binds own them). Both accepted losses.

## Terminal (Ghostty + tmux)

Both machines use `linux/omarchy/config/tmux/tmux.conf` and `wl-copy`. tmux loads one user file, `~/.config/tmux/tmux.conf`.

| Key | Action | Linux |
|---|---|---|
| Ctrl+B | tmux prefix (stock) | tmux.conf |
| Ctrl+B then pipe / minus | tmux split horizontal / vertical | tmux.conf |
| Mouse drag in tmux | copy to system clipboard (mouse on) | tmux.conf |
| Shift+Enter | newline (Claude Code) | Ghostty config + tmux passthrough |
| Super+T | new terminal tab | Ghostty `super+t` |

## System

| Key | Action | Linux |
|---|---|---|
| Super+Ctrl+L | lock | Omarchy |
| Ctrl+Space | keyboard layout us/ara | `input.lua` `grp:ctrl_space_toggle` |
| Super+Ctrl+R | reload Hyprland | bindings.lua |
| Print / Super+Print / Super+Ctrl+Print | Omarchy capture / colour picker / OCR | Omarchy |

Omarchy's own Alt-based extras (group moves, scratchpad send, maximize, precise volume) stay bound on Linux by decision: never pressed, never collide.

## Mouse

Click to focus on both machines (`follow_mouse = 2` in `input.lua`). Hovering never moves keyboard focus; scrolling still goes to the window under the cursor.

## Known losses (accepted)

- Ctrl+Space is the layout toggle, so editor autocomplete on Ctrl+Space is gone on both.
