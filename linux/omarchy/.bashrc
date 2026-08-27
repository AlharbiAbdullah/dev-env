# ~/.bashrc on Omarchy 4: Omarchy's defaults first, then the same additions the Ubuntu box had.
[[ $- != *i* ]] && return

# ble.sh (AUR blesh-git installs to /usr/share/blesh). Loads first, attaches last.
[[ -r /usr/share/blesh/ble.sh ]] && source /usr/share/blesh/ble.sh --noattach

# Omarchy defaults (aliases, functions, prompt bits). Do not edit; override below.
[[ -r ~/.local/share/omarchy/default/bash/rc ]] && source ~/.local/share/omarchy/default/bash/rc

# --- PATH ---
export PATH="$HOME/.local/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export BUN_INSTALL="$HOME/.bun"; export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
[ -r "$HOME/google-cloud-sdk/path.bash.inc" ] && source "$HOME/google-cloud-sdk/path.bash.inc"

# --- locale / history ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
HISTSIZE=50000; HISTFILESIZE=50000; HISTCONTROL=ignoreboth:erasedups; shopt -s histappend

# --- tools (Omarchy's rc already inits starship + zoxide + fzf; guard against double init) ---
command -v starship >/dev/null && [[ -z "${STARSHIP_SHELL:-}" ]] && eval "$(starship init bash)"
command -v zoxide  >/dev/null && ! type __zoxide_z >/dev/null 2>&1 && eval "$(zoxide init bash)"
command -v fzf     >/dev/null && ! type __fzf_select__ >/dev/null 2>&1 && eval "$(fzf --bash)"

# --- aliases (same as Ubuntu) ---
if command -v eza >/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -l --icons --group-directories-first --git"
  alias la="eza -la --icons --group-directories-first --git"
  alias lt="eza --tree --icons --level=2"
fi
alias cl="claude"; alias oc="opencode"; alias gm="gemini"; alias cur="cursor"; alias lg="lazygit"
alias g="git"; alias gs="git status"; alias gd="git diff"; alias gco="git checkout"; alias gcb="git checkout -b"
alias gp="git push"; alias gl="git pull"; alias c='clear'; alias up="omarchy update"

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
