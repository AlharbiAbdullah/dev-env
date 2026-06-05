# =============================================================================
# PATH
# =============================================================================
export PATH="$HOME/.local/bin:$PATH"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null && eval "$(pyenv init --path)"

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
