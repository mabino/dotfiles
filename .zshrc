# --- Environment Variables ---
export ZSH="$HOME/.oh-my-zsh"
export NODE_EXTRA_CA_CERTS=$(python3 -m certifi)
export NODE_USE_SYSTEM_CA=1
export HOMEBREW_NO_ENV_HINTS=1

# --- Path Configuration ---
export PATH="$HOME/.local/bin:$PATH"

# --- Oh My Zsh Setup ---
ZSH_THEME="robbyrussell"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# --- Tool Initializations ---
eval "$($HOME/homebrew/bin/brew shellenv)"
eval "$(zoxide init zsh)"
eval "$(mise activate zsh)"

# Conda Initialization
__conda_setup="$('/Users/mabino/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/mabino/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/mabino/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/mabino/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# --- SSH Configuration ---
ssh-add --apple-load-keychain 2>/dev/null

# --- Yadm Automation Helpers ---
# Internal helper to sync specific files with yadm
function _yadm_sync() {
  local file="$1"
  local msg="$2"
  yadm add "$file"
  if ! yadm diff --cached --quiet; then
    yadm commit -m "$msg"
    yadm push
  else
    echo "No changes in ${file##*/} detected."
  fi
}

# --- Tool Wrappers ---

# Brew wrapper to sync Brewfile on change
function brew() {
  command brew "$@"
  local EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 0 ]]; then
    case "$1" in
      install|uninstall|tap|untap|upgrade|cleanup)
        echo "Updating Brewfile and syncing with yadm..."
        command brew bundle dump --force --file=~/.Brewfile
        _yadm_sync ~/.Brewfile "Auto-update Brewfile after brew $1"
        ;;
    esac
  fi
  return $EXIT_CODE
}

# Mise wrapper to sync global config on change
function mise() {
  command mise "$@"
  local EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 0 && "$1" == "use" && "$2" == "--global" ]]; then
    echo "Updating ~/.config/mise/config.toml and syncing with yadm..."
    _yadm_sync ~/.config/mise/config.toml "Auto-update mise config.toml after mise $1"
  fi
  return $EXIT_CODE
}

# --- Aliases ---
alias empty="osascript -e 'try' -e 'tell application \"Finder\" to empty trash' -e 'end try' -e 'display notification \"The bin is clear!\" with title \"Trash Emptied\"'"
