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
export OPENCODE_DISABLE_CLAUDE_CODE=1   # opencode gets Rai from its own edges, never ~/.claude (helm 03-rai/harness/opencode)
alias cl="claude"; alias cur="cursor"; alias lg="lazygit"
alias gs="git status"; alias gd="git diff"; alias gco="git checkout"; alias gcb="git checkout -b"
alias gp="git push"; alias gl="git pull"
alias up="omarchy update"; alias ur="uv run"
alias lt="eza --tree --level=2 --long --icons --git"
alias c="clear"; alias oc="opencode --auto"   # Omarchy binds c=opencode; c is clear here
alias agy="agy --dangerously-skip-permissions"   # agy yolo: no settings key, flag only
alias la="ls -a"
alias cx="codex"   # Omarchy binds cx=claude; cx is codex here

# Rai's orchestrator (helm 03-rai/agents/orchestrator.md) is the main agent of every interactive
# Claude Code session, appended to the built-in system prompt, which stays. Not exported: scripts,
# `claude -p` jobs and script-started tmux workers run the plain binary. Subcommands and runs that
# set their own system prompt or agent pass through. It runs only while helm's
# 03-rai/agents/rollout.json turns it on for claude; RAI_ORCHESTRATOR=0 turns it off for a shell.
claude() {
  local orch="$HOME/helm/03-rai/agents/orchestrator.md" a
  if [[ "${RAI_ORCHESTRATOR:-1}" == 0 || ! -r "$orch" ]] \
     || ! grep -q '"claude": *true' "$HOME/helm/03-rai/agents/rollout.json" 2>/dev/null; then
    command claude "$@"; return
  fi
  case "${1:-}" in
    agents|attach|auth|auto-mode|doctor|gateway|import|install|logs|mcp|plugin|plugins|purge|\
    respawn|rm|setup-token|stop|kill|ultrareview|update|upgrade) command claude "$@"; return ;;
  esac
  for a in "$@"; do
    case "$a" in
      -p|--print|-v|--version|-h|--help|--agent|--agent=*|--system-prompt|--system-prompt=*|\
      --system-prompt-file|--system-prompt-file=*|--append-system-prompt|--append-system-prompt=*|\
      --append-system-prompt-file|--append-system-prompt-file=*) command claude "$@"; return ;;
    esac
  done
  command claude --append-system-prompt-file "$orch" "$@"
}

# The same orchestrator for interactive codex sessions, as developer_instructions on top of codex's
# own prompt (a custom agent or ~/.codex/AGENTS.md would reach the specialists too). `exec` and
# every other subcommand pass through, so scripts and council voices never get it. rollout.json
# turns it on for codex.
codex() {
  local orch="$HOME/helm/03-rai/agents/orchestrator.md" a
  if [[ "${RAI_ORCHESTRATOR:-1}" == 0 || ! -r "$orch" ]] \
     || ! grep -q '"codex": *true' "$HOME/helm/03-rai/agents/rollout.json" 2>/dev/null; then
    command codex "$@"; return
  fi
  case "${1:-}" in
    agents|exec|e|review|login|logout|mcp|plugin|app-server|remote-control|completion|update|doctor|\
    sandbox|debug|apply|a|queue|archive|delete|migrate-rollouts|unarchive|cloud|exec-server|features|\
    help) command codex "$@"; return ;;
  esac
  for a in "$@"; do
    case "$a" in
      -h|--help|-V|--version|*developer_instructions=*) command codex "$@"; return ;;
    esac
  done
  command codex -c "developer_instructions=$(cat "$orch")" "$@"
}

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

# Added by Antigravity CLI installer
export PATH="/home/abdullah/.local/bin:$PATH"
# Added by dbt Fusion extension
alias dbtf=/home/abdullah/.local/bin/dbt
