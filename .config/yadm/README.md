# 🏠 Dotfiles Management (yadm)

This repository manages my macOS development environment using `yadm`.

## 🚀 Key Features & Automations

### 🤖 AI Agent Strategy ("Master & Proxy")
To maintain a "Single Source of Truth" across multiple AI assistants (Claude, Gemini, etc.), I use a master configuration:
- **Master File**: `~/.AGENT.md` contains all global engineering standards and preferences.
- **Symlinks**: 
  - `~/.claude/CLAUDE.md` -> `~/.AGENT.md`
  - `~/.gemini/GEMINI.md` -> `~/.AGENT.md`
- **Benefit**: Update your preferences once in `~/.AGENT.md`, and every AI assistant instantly inherits the changes.

### 📦 Homebrew Automation
The `brew` command is wrapped in `~/.zshrc`. 
- **Auto-Sync**: Any `install`, `uninstall`, or `upgrade` automatically triggers a `brew bundle dump` to `~/.Brewfile`.
- **Auto-Commit**: If changes are detected, `yadm` automatically commits and pushes the updated `Brewfile` to GitHub.

### 🛠 Runtime Management (mise)
Switched from `asdf` to **`mise`** for faster, Rust-based runtime management.
- **Tracking**: `~/.tool-versions` is tracked by `yadm`.
- **Automation**: Global version changes via `mise use --global` are automatically committed and pushed.

### 🔑 SSH: Local Include with Fallback
To handle multiple devices with unique private keys safely:
- **`~/.ssh/config`**: Tracks global aliases and defaults. It includes `Include config_local` at the top.
- **`~/.ssh/config_local`**: Stores device-specific `IdentityFile` paths. This file is **ignored** by git.
- **Fallback**: The main config includes generic fallbacks (`~/.ssh/id_ed25519`) if the local key isn't found.

### 🔍 Search & Navigation
- **`fzf`**: Fuzzy finder for files, history, and processes.
- **`zoxide`**: A smarter `cd` command that learns your habits.

### 🛡 Security & Hygiene
- **`.gitignore_global`**: A comprehensive global ignore file that prevents accidental commits of:
  - AI configuration files (`.claude`, `.gemini`, etc.)
  - Secrets (`.env`, `.pem`, `secrets.json`)
  - Development caches (`node_modules`, `__pycache__`, `dist/`)

## 🛠 Usage
```bash
# Clone to a new machine
yadm clone git@github.com:mabino/dotfiles.git

# Install all packages
brew bundle --global

# Set up local SSH key
echo "Host *\n  IdentityFile ~/.ssh/YOUR_KEY" > ~/.ssh/config_local
```
