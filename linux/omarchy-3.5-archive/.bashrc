# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# ble.sh - Bash Line Editor (autosuggestions + syntax highlighting)
[[ $- == *i* ]] && source /usr/share/blesh/ble.sh --noattach

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# AI tool aliases
alias cl="claude"
alias gm="gemini"
alias cur="cursor"
alias c="clear"
alias up="omarchy-update"

# ble.sh attach (must be at the bottom of .bashrc)
[[ ${BLE_VERSION-} ]] && ble-attach
