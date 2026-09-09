# ~/.bashrc on Omarchy 4. Same shape as /etc/skel/.bashrc: Omarchy's defaults
# win (envs, PATH, history, aliases, fns, mise/starship/zoxide/fzf init, inputrc).
# Only what Omarchy does not provide lives below the rc source.

# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else
[[ $- != *i* ]] && return

# ble.sh (AUR blesh-git installs to /usr/share/blesh). Loads first, attaches last.
[[ -r /usr/share/blesh/ble.sh ]] && source /usr/share/blesh/ble.sh --noattach

# All the default Omarchy aliases and functions (never edit those; override here)
source "$OMARCHY_PATH/default/bash/rc"

# --- additions Omarchy does not provide ---
export FZF_DEFAULT_OPTS="--color=16"   # follow the terminal palette (= active theme)
alias cl="claude"; alias cur="cursor"; alias lg="lazygit"
alias gs="git status"; alias gd="git diff"; alias gco="git checkout"; alias gcb="git checkout -b"
alias gp="git push"; alias gl="git pull"
alias up="omarchy update"; alias ur="uv run"

# atuin: synced, encrypted shell history (hosted sync, choice 2026-09-09). Needs ble.sh loaded
# first (done above); ble.sh >= 0.4 is atuin's supported bash hook, so no bash-preexec.
command -v atuin >/dev/null && eval "$(atuin init bash)"

# Machine-local secrets (gitignored)
[ -r "$HOME/.bashrc.local" ] && source "$HOME/.bashrc.local"

# --- ble.sh attach (keep LAST) + zsh-style green valid commands ---
[[ ${BLE_VERSION-} ]] && ble-attach
# Ghostty appends __ghostty_hook to PROMPT_COMMAND after this file. Its OSC 133;A
# mark jumps to a fresh line whenever the cursor is not at column 0, and at
# ble.sh's deferred attach that hook runs right after ble.sh drew the first
# prompt, so the prompt showed twice on every new terminal. This CR sits between
# ble.sh's slot and Ghostty's hook and keeps the cursor at column 0 (harmless
# on every later prompt). Must stay AFTER ble-attach, else it runs too early.
__rai_precmd_cr() { printf '\r'; }
PROMPT_COMMAND+=(__rai_precmd_cr)
if [[ ${BLE_VERSION-} ]]; then
  ble-face -s command_builtin fg=green; ble-face -s command_file fg=green
  ble-face -s command_function fg=green; ble-face -s command_alias fg=green
fi
