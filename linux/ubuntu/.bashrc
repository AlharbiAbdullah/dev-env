# =============================================================================
# ble.sh — fish-style autosuggestions + syntax highlighting (must load first)
# Attaches at the very bottom of this file via `ble-attach` so it doesn't
# fight starship/fzf init. Remove these two lines to fully disable.
# =============================================================================
[[ $- == *i* ]] && source "$HOME/.local/share/blesh/ble.sh" --noattach

# =============================================================================
# PATH
# =============================================================================
export PATH="$HOME/.local/bin:$PATH"

# uv (Python; installs to ~/.local/bin, already on PATH)

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# =============================================================================
# LOCALE
# =============================================================================
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# =============================================================================
# HISTORY
# =============================================================================
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# =============================================================================
# COMPLETION
# =============================================================================
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# =============================================================================
# TOOLS
# =============================================================================
command -v starship >/dev/null && eval "$(starship init bash)"
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
command -v fzf >/dev/null && fzf --bash >/dev/null 2>&1 && eval "$(fzf --bash)"

# =============================================================================
# ALIASES
# =============================================================================
if command -v eza >/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -l --icons --group-directories-first --git"
  alias la="eza -la --icons --group-directories-first --git"
  alias lt="eza --tree --icons --level=2"
fi

# Ubuntu ships bat as batcat; alias only if batcat exists and bat does not
if command -v batcat >/dev/null && ! command -v bat >/dev/null; then
  alias bat="batcat"
fi

alias cl="claude"
alias oc="opencode"
alias gm="gemini"
alias cur="cursor"
alias lg="lazygit"
alias g="git"
alias gs="git status"
alias gd="git diff"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gp="git push"
alias gl="git pull"
alias c='clear'

# Machine-local secrets and overrides (gitignored, never committed)
[ -r "$HOME/.bashrc.local" ] && source "$HOME/.bashrc.local"


# Added by Antigravity CLI installer
export PATH="/home/abdullah/.local/bin:$PATH"

# =============================================================================
# ble.sh — attach (keep LAST; lets all init above run before ble takes over)
# =============================================================================
[[ ${BLE_VERSION-} ]] && ble-attach

# zsh-syntax-highlighting style: valid commands in green (default ble is cyan)
if [[ ${BLE_VERSION-} ]]; then
  ble-face -s command_builtin  fg=green
  ble-face -s command_file     fg=green
  ble-face -s command_function fg=green
  ble-face -s command_alias    fg=green
fi

# opencode
export PATH=/home/abdullah/.opencode/bin:$PATH

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
source "$HOME/google-cloud-sdk/path.bash.inc"

# =============================================================================
# DISPLAY autodetect — this box is headless (no monitor). SSH/TTY sessions get no
# DISPLAY, so browsers and any GUI tool fail to start. Chrome Remote Desktop runs a
# virtual X server (usually :20) that needs no monitor; point at whatever is live.
# Set RAI_NO_DISPLAY_AUTODETECT=1 to skip. ~110ms, only when DISPLAY is unset.
# =============================================================================
if [ -z "${DISPLAY:-}" ] && [ -z "${RAI_NO_DISPLAY_AUTODETECT:-}" ]; then
  _rai_display="$("$HOME/helm/03-rai/harness/linux/detect-display.sh" 2>/dev/null)" \
    && export DISPLAY="$_rai_display"
  unset _rai_display
fi
