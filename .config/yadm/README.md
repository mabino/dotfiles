# 🏠 Dotfiles Management (yadm)

This repository manages my macOS development environment using `yadm`.

## 🚀 Quick Start (New Machine Bootstrap)

On any fresh or re-imaged Mac, run this single command in Terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mabino/dotfiles/main/.local/bin/bootstrap-mac)"
```

For silent / unattended automation:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mabino/dotfiles/main/.local/bin/bootstrap-mac)" -- --silent
```

To clean up and reset / start over:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mabino/dotfiles/main/.local/bin/bootstrap-mac)" -- --reset
```
Or reset and reinstall in one shot:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mabino/dotfiles/main/.local/bin/bootstrap-mac)" -- --reinstall
```

---

## 🛠 Key Features & Automations

### 🏷 Hardware Identification (`FYB-<Serial>`)
- Automatically detects the Mac's hardware serial number from IORegistry.
- Sets `ComputerName` and `HostName` to `FYB-<Serial>`.
- Generates dedicated SSH key pair `~/.ssh/FYB-<Serial>_id_ed25519`.

### 🔑 SSH: Automated Discovery & Keychain Persistence (`ssh-reconcile`)
To handle multiple devices with unique private keys safely and persist passphrases seamlessly across reboots:
- **`~/.ssh/config`**: Publicly safe global defaults (`Host *`, fallback keys, aliases). Includes `config_local` at top.
- **`~/.ssh/config_local`**: Stores device-specific `IdentityFile` paths. Auto-generated and managed by `ssh-reconcile`, ignored by git.
- **macOS Keychain Integration**:
  - `ssh-reconcile enroll`: Prompts for the passphrase once per machine and permanently stores it in macOS Keychain with `ssh-add --apple-use-keychain`.
  - `ssh-reconcile load`: Called on shell startup in `~/.zshrc` to ensure `config_local` is synced and keys are loaded via `ssh-add --apple-load-keychain`.
  - `ssh-reconcile status`: Inspects local keys, agent status, and keychain enrollment state.

### 🤖 AI Agent Strategy ("Master & Proxy")
To maintain a "Single Source of Truth" across multiple AI assistants (Claude, Gemini, etc.), I use a master configuration:
- **Master File**: `~/.AGENT.md` contains all global engineering standards and preferences.
- **Symlinks**: 
  - `~/.claude/CLAUDE.md` -> `~/.AGENT.md`
  - `~/.gemini/GEMINI.md` -> `~/.AGENT.md`
  - `~/.copilot/copilot-instructions.md` -> `~/.AGENT.md`
- **Benefit**: Update your preferences once in `~/.AGENT.md`, and every AI assistant instantly inherits the changes.

### 📦 Homebrew Automation
The `brew` command is wrapped in `~/.zshrc`. 
- **Auto-Sync**: Any `install`, `uninstall`, or `upgrade` automatically triggers a `brew bundle dump` to `~/.Brewfile`.
- **Union Merge Driver**: Custom `brewfile-reconcile` driver prevents package loss across multiple machines.
- **Auto-Commit**: If changes are detected, `yadm` automatically commits and pushes the updated `Brewfile` to GitHub.

### 🐚 Shell & Oh My Zsh
- Automated unattended installation of **Oh My Zsh** during bootstrap.
- Configured in `~/.zshrc` with `robbyrussell` theme and standard plugins.
- Guarded to ensure shell starts smoothly even on systems before Oh My Zsh is installed.

### 🪝 Yadm Lifecycle Hooks
Automated hooks in `~/.config/yadm/hooks/`:
- **`post_pull`**: Automatically triggers `ssh-reconcile sync`, verifies the Brewfile merge driver, and refreshes AI symlinks upon pulling updates.
- **`post_clone`**: Automatically triggers `~/.config/yadm/bootstrap` on initial clone.

### 🧪 Containerized Testing & CI
All dotfiles tools (`brewfile-reconcile`, `ssh-reconcile`) include a full unit test suite:
- **Local & Container Runner**: Execute locally via `python3 -m unittest discover ~/.config/yadm/tests` or containerized via `~/.config/yadm/run_tests_container.sh`.
- **GitHub Actions**: Automated CI workflow (`.github/workflows/ci.yml`) runs tests on Linux in Docker on every push/PR.

### 🛡 Security & Hygiene
- **`.gitignore_global`**: A comprehensive global ignore file that prevents accidental commits of:
  - AI configuration files (`.claude`, `.gemini`, etc.)
  - Secrets (`.env`, `.pem`, `secrets.json`, private keys, `config_local`)
  - Development caches (`node_modules`, `__pycache__`, `dist/`)

## 🛠 Commands Reference
```bash
# Clone to an existing machine
yadm clone git@github.com:mabino/dotfiles.git

# Bootstrap or repair system setup
yadm bootstrap

# Check SSH key status or enroll new keys
ssh-reconcile status
ssh-reconcile enroll

# Run test suite in Docker
~/.config/yadm/run_tests_container.sh
```
