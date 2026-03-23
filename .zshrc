
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

eval "$($HOME/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_ENV_HINTS=1

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

eval "$(mise activate zsh)"

export PATH="$HOME/.local/bin:$PATH"

function brew() {
  command brew "$@"
  local EXIT_CODE=$?
  
  if [[ $EXIT_CODE -eq 0 ]]; then
    case "$1" in
      install|uninstall|tap|untap|upgrade|cleanup)
        echo "Updating Brewfile and syncing with yadm..."
        command brew bundle dump --force --file=~/.Brewfile
        yadm add ~/.Brewfile
        if ! yadm diff --cached --quiet; then
          yadm commit -m "Auto-update Brewfile after brew $1"
          yadm push
        else
          echo "No changes in Brewfile detected."
        fi
        ;;
    esac
  fi
  
  return $EXIT_CODE
}
eval "$(zoxide init zsh)"

function mise() {
  command mise "$@"
  local EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 0 && "$1" == "use" && "$2" == "--global" ]]; then
    echo "Updating ~/.config/mise/config.toml and syncing with yadm..."
    yadm add ~/.config/mise/config.toml
    if ! yadm diff --cached --quiet; then
      yadm commit -m "Auto-update mise config.toml after mise $1"
      yadm push
    else
      echo "No changes in config.toml detected."
    fi
  fi
  return $EXIT_CODE
}

export NODE_EXTRA_CA_CERTS=$(python3 -m certifi)
export NODE_USE_SYSTEM_CA=1

ssh-add --apple-load-keychain 2>/dev/null

alias empty="osascript -e 'try' -e 'tell application \"Finder\" to empty trash' -e 'end try' -e 'display notification \"The bin is clear!\" with title \"Trash Emptied\"'"
