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
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# =============================================================================
# COMPLETION
# =============================================================================
autoload -Uz compinit
compinit

# =============================================================================
# ZSH PLUGINS (apt-installed, replace oh-my-zsh)
# =============================================================================
[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# =============================================================================
# TOOLS
# =============================================================================
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
command -v fzf >/dev/null && fzf --zsh >/dev/null 2>&1 && source <(fzf --zsh)

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
[ -r "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
