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

### 🔑 SSH: Automated Discovery & Keychain Persistence (`ssh-reconcile`)
To handle multiple devices with unique private keys safely and persist passphrases seamlessly across reboots:
- **`~/.ssh/config`**: Tracks global aliases and defaults. It includes `Include config_local` at the top.
- **`~/.ssh/config_local`**: Stores device-specific `IdentityFile` paths. Auto-generated and managed by `ssh-reconcile`, ignored by git.
- **macOS Keychain Integration**:
  - `ssh-reconcile enroll`: Prompts for the passphrase once per machine and permanently stores it in macOS Keychain with `ssh-add --apple-use-keychain`.
  - `ssh-reconcile load`: Called on shell startup in `~/.zshrc` to ensure `config_local` is synced and keys are loaded via `ssh-add --apple-load-keychain`.
  - `ssh-reconcile status`: Inspects local keys, agent status, and keychain enrollment state.

### 🔍 Search & Navigation
- **`fzf`**: Fuzzy finder for files, history, and processes.

### 🛡 Security & Hygiene
- **`.gitignore_global`**: A comprehensive global ignore file that prevents accidental commits of:
  - AI configuration files (`.claude`, `.gemini`, etc.)
  - Secrets (`.env`, `.pem`, `secrets.json`, private keys, `config_local`)
  - Development caches (`node_modules`, `__pycache__`, `dist/`)

## 🛠 Usage
```bash
# Clone to a new machine
yadm clone git@github.com:mabino/dotfiles.git

# Bootstrap system (SSH reconciliation, git hooks, package setup)
yadm bootstrap

# Check SSH key status or enroll new keys
ssh-reconcile status
ssh-reconcile enroll
```
