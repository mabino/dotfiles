# --- Path & Homebrew Configuration ---
export PATH="$HOME/.local/bin:$PATH"

# Homebrew lives at ~/.homebrew (preferred); fall back for machines not yet migrated.
# Clear stale env inherited from a shell that predates a prefix move, otherwise
# `brew shellenv` assumes it is already configured and emits nothing.
if [[ -n $HOMEBREW_PREFIX && ! -x $HOMEBREW_PREFIX/bin/brew ]]; then
  unset HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY
fi
for _brew in "$HOME/.homebrew/bin/brew" "$HOME/homebrew/bin/brew" /opt/homebrew/bin/brew; do
  if [[ -x $_brew ]]; then
    eval "$($_brew shellenv)"
    [[ ":$PATH:" == *":${_brew%/brew}:"* ]] || export PATH="${_brew%/brew}:$PATH"
    break
  fi
done
unset _brew

# --- Environment Variables ---
export ZSH="$HOME/.oh-my-zsh"
export HOMEBREW_NO_ENV_HINTS=1
export NODE_USE_SYSTEM_CA=1

# Node extra CA certificates (from Homebrew certifi / ca-certificates if available)
if command -v python3 >/dev/null 2>&1; then
  _certifi_path="$(python3 -m certifi 2>/dev/null || true)"
  [[ -n "$_certifi_path" ]] && export NODE_EXTRA_CA_CERTS="$_certifi_path"
  unset _certifi_path
elif [[ -n "$HOMEBREW_PREFIX" && -f "$HOMEBREW_PREFIX/etc/ca-certificates/cert.pem" ]]; then
  export NODE_EXTRA_CA_CERTS="$HOMEBREW_PREFIX/etc/ca-certificates/cert.pem"
fi

# --- Oh My Zsh Setup ---
if [[ -d "$ZSH" && -f "$ZSH/oh-my-zsh.sh" ]]; then
  ZSH_THEME="robbyrussell"
  plugins=(git)
  source "$ZSH/oh-my-zsh.sh"
fi

# Mise runtime activation
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

# Conda Initialization
for _conda_root in "$HOME/miniconda3" "$HOME/anaconda3" "$HOME/.miniconda" /opt/homebrew/Caskroom/miniconda; do
  if [[ -x "$_conda_root/bin/conda" ]]; then
    __conda_setup="$("$_conda_root/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
      eval "$__conda_setup"
    elif [ -f "$_conda_root/etc/profile.d/conda.sh" ]; then
      . "$_conda_root/etc/profile.d/conda.sh"
    else
      export PATH="$_conda_root/bin:$PATH"
    fi
    unset __conda_setup
    break
  fi
done
unset _conda_root

# --- SSH Configuration ---
# Reconcile device-specific SSH identities and load saved passphrases from Keychain
if command -v ssh-reconcile >/dev/null 2>&1; then
  ssh-reconcile load
else
  ssh-add --apple-load-keychain 2>/dev/null
fi

# --- Yadm Automation Helpers ---
# Ensure the Brewfile union merge driver is registered in this machine's
# yadm repo (pairs with .gitattributes: `.Brewfile merge=brewfile-union`)
function _yadm_ensure_merge_driver() {
  if ! yadm gitconfig --get merge.brewfile-union.driver >/dev/null 2>&1; then
    yadm gitconfig merge.brewfile-union.name "Union merge for Brewfiles"
    yadm gitconfig merge.brewfile-union.driver "$HOME/.local/bin/brewfile-reconcile git-merge %O %A %B"
  fi
}

# Internal helper to sync specific files with yadm
function _yadm_sync() {
  local file="$1"
  local msg="$2"
  _yadm_ensure_merge_driver
  yadm add "$file"
  if yadm diff --cached --quiet; then
    echo "No changes in ${file##*/} detected."
    return 0
  fi
  yadm commit -m "$msg"
  if ! yadm push --quiet 2>/dev/null; then
    echo "Remote has new commits; rebasing and retrying push..."
    if yadm pull --rebase --autostash --quiet && yadm push --quiet; then
      echo "Synced after rebase."
    else
      yadm rebase --abort 2>/dev/null
      echo "yadm sync needs manual attention: run 'yadm pull --rebase' and resolve conflicts." >&2
      return 1
    fi
  fi
}

# --- Tool Wrappers ---

# Brew wrapper to reconcile and sync the Brewfile on change. The Brewfile is
# the union of packages across machines: a fresh dump is merged with the
# latest pulled Brewfile so other machines' packages are never dropped, and
# uninstalled packages are removed explicitly.
function brew() {
  command brew "$@"
  local EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 0 ]]; then
    case "$1" in
      install|uninstall|remove|rm|tap|untap|upgrade|cleanup)
        echo "Updating Brewfile and syncing with yadm..."
        _yadm_ensure_merge_driver
        yadm pull --rebase --autostash --quiet 2>/dev/null
        local dump_file
        dump_file="$(mktemp)"
        command brew bundle dump --force --file="$dump_file"
        local -a remove_args=()
        if [[ "$1" == (uninstall|remove|rm|untap) ]]; then
          local arg
          for arg in "${@:2}"; do
            [[ "$arg" == -* ]] || remove_args+=(--remove "$arg")
          done
        fi
        if "$HOME/.local/bin/brewfile-reconcile" union "$dump_file" "$HOME/.Brewfile" "${remove_args[@]}" -o "$HOME/.Brewfile"; then
          _yadm_sync ~/.Brewfile "Auto-update Brewfile after brew $1"
        else
          echo "Brewfile reconcile failed; ~/.Brewfile left untouched and not synced." >&2
        fi
        rm -f "$dump_file"
        ;;
    esac
  fi
  return $EXIT_CODE
}

# AI Assistant Wrappers (auto-approve tool permissions)
function agy() {
  command agy --dangerously-skip-permissions "$@"
}

function claude() {
  command claude --dangerously-skip-permissions "$@"
}

function copilot() {
  command copilot --allow-all "$@"
}


# --- Aliases ---
alias empty="osascript -e 'try' -e 'tell application \"Finder\" to empty trash' -e 'end try' -e 'display notification \"The bin is clear!\" with title \"Trash Emptied\"'"

# Ollama Qwen Server Shortcuts
alias start-qwen-server="$HOME/.pi/agent/start_ollama.sh"
alias stop-qwen-server="$HOME/.pi/agent/stop_ollama.sh"

# Local oMLX + Pi Agent Shortcuts
alias start-omlx-server="$HOME/.local/bin/omlx-server start"
alias stop-omlx-server="$HOME/.local/bin/omlx-server stop"
alias restart-omlx-server="$HOME/.local/bin/omlx-server restart"
alias status-omlx-server="$HOME/.local/bin/omlx-server status"

function pi-local() {
  (
    cd "$HOME/local-coding-agent" 2>/dev/null || { echo "local-coding-agent workspace not found at ~/local-coding-agent. Run bootstrap-local-agent." >&2; return 1; }
    if command -v mise >/dev/null 2>&1; then
      mise exec -- npx pi --provider omlx --model "omlx/Qwen3.8-27B-4bit" "$@"
    else
      npx pi --provider omlx --model "omlx/Qwen3.8-27B-4bit" "$@"
    fi
  )
}

[[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/opt/rustup/bin" ]] && export PATH="$HOMEBREW_PREFIX/opt/rustup/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
