# =============================================================================
# PATH
# =============================================================================
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"

# mise owns node, claude, gh, opencode, pi (same config.toml as the hub)
command -v mise >/dev/null && eval "$(mise activate zsh)"

# =============================================================================
# LOCALE
# =============================================================================
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export FZF_DEFAULT_OPTS="--color=16"   # follow the terminal palette (= active theme)

# =============================================================================
# COMPLETION
# =============================================================================
autoload -Uz compinit
compinit

# =============================================================================
# ZSH PLUGINS (brew-installed, replace oh-my-zsh)
# =============================================================================
[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# =============================================================================
# TOOLS
# =============================================================================
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
command -v fzf >/dev/null && source <(fzf --zsh)
# atuin: synced, encrypted shell history (hosted sync, choice 2026-09-09). After fzf so
# atuin owns Ctrl-R and the up arrow.
command -v atuin >/dev/null && eval "$(atuin init zsh)"

# =============================================================================
# ALIASES
# =============================================================================
# Omarchy's eza set, same as the hub (ruling 2026-09-09: one shell shape where it maps)
if command -v eza >/dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

alias python="python3"
alias cl="claude"
alias cx='printf "\033[2J\033[3J\033[H" && claude --permission-mode auto'
alias c='opencode --auto'
alias t='tmux attach || tmux new -s Work'
alias mup='MISE_MINIMUM_RELEASE_AGE=0 mise up'
alias cur="cursor"
alias lg="lazygit"
alias g="git"
alias gs="git status"
alias gd="git diff"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gp="git push"
alias gl="git pull"

# code .        -> VS Code here on the Mac (cur . -> Cursor)
# code remote   -> VS Code over SSH on the Linux box, same folder (synced roots map 1:1)
code() {
  if [[ "$1" == "remote" ]]; then
    local p="${2:-$PWD}"
    p="$(cd "$p" 2>/dev/null && pwd)" || { echo "code remote: no such folder: $2" >&2; return 1; }
    command code --remote ssh-remote+linux "${p/#$HOME//home/abdullah}"
  else
    command code "$@"
  fi
}

# Machine-local secrets and overrides (gitignored, never committed)
[ -r "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
