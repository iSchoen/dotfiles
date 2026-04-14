# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

export MISE_DATA_DIR="$HOME/.local/share/mise"
eval "$(mise activate bash)"

# Re-init zoxide last so it hooks cd after everything else
if command -v zoxide &> /dev/null; then
  export _ZO_DOCTOR=0
  eval "$(zoxide init bash)"
fi
