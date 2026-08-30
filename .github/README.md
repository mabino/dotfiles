# My Dotfiles

These are my personal dotfiles, managed seamlessly with [yadm](https://yadm.io/) (Yet Another Dotfiles Manager).

## 🚀 Quick Start (Brand New Mac Setup)

On a fresh or re-imaged macOS machine, open Terminal and run the single-command bootstrap:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mabino/dotfiles/main/.local/bin/bootstrap-mac)"
```

Or for completely unattended / silent automation:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mabino/dotfiles/main/.local/bin/bootstrap-mac)" -- --silent
```

### 🧹 Reset / Start Over (Clean Slate):
To clean up all bootstrap installations and start fresh:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mabino/dotfiles/main/.local/bin/bootstrap-mac)" -- --reset
```
Or to reset and immediately re-run the full bootstrap in one shot:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mabino/dotfiles/main/.local/bin/bootstrap-mac)" -- --reinstall
```

### What This Automates (From Bare Metal):
1. **Hardware Identification (`FYB-<Serial>`)**: Automatically detects the machine serial number from IORegistry and sets macOS `ComputerName` and `HostName` to `FYB-<Serial>`.
2. **Xcode Command Line Tools**: Installs or verifies CLT headlessly.
3. **Homebrew Environment**: Installs Homebrew non-interactively and configures `shellenv`.
4. **SSH & Keychain Integration**:
   - Generates a dedicated `~/.ssh/FYB-<Serial>_id_ed25519` private key.
   - Prompts for your Mac's local login password once and permanently writes it into the **macOS Data Protection Keychain** via `ssh-add --apple-use-keychain`.
5. **GitHub Key Registration**: Installs `gh` CLI, authenticates via browser, and uploads the new public key to GitHub with title `FYB-<Serial>`.
6. **Dotfiles via Yadm**: Clones the repository over SSH (`git@github.com:mabino/dotfiles.git`) with automatic HTTPS fallback.
7. **Git Hooks & Merge Drivers**: Configures global Git hooks and registers the `brewfile-reconcile` union merge driver.
8. **SSH Config Reconciliation**: Runs `ssh-reconcile sync` to generate `~/.ssh/config_local`.
9. **Oh My Zsh Setup**: Installs Oh My Zsh unattended with `robbyrussell` theme and git plugins without overriding your customized `.zshrc`.
10. **Master AI Instructions**: Symlinks `~/.AGENT.md` to Claude (`CLAUDE.md`), Gemini (`GEMINI.md`), and Copilot (`copilot-instructions.md`).
11. **Homebrew Package Bundle**: Installs all tracked CLI tools, packages, and GUI apps via `brew bundle --global`.

---

## 🛠 Manual Installation & Maintenance

If you already have Git and `yadm` installed, you can clone or run maintenance tasks directly:

```bash
# Clone repository
yadm clone git@github.com:mabino/dotfiles.git

# Re-run bootstrap anytime to repair or verify system setup
yadm bootstrap

# Check SSH key status or enroll new keys
ssh-reconcile status
ssh-reconcile enroll

# Run containerized test suite
~/.config/yadm/run_tests_container.sh
```

---

## 🔒 Security & Separation of Concerns

- **Public Repository Safe**: Contains zero private keys, zero API tokens, and zero machine-specific credentials.
- **Local Key Isolation**: Device-specific paths (`~/.ssh/config_local`) and private environment files (`.env`, `secrets.json`, `*.pem`) are globally ignored via `~/.gitignore_global`.
- **Automated Keychain Persistence**: Passphrases are stored strictly in the macOS Data Protection Keychain and auto-loaded across reboots.

---

## Fallback Usage (Without yadm)

If you find yourself on a system where you **cannot** install `yadm`, you can still easily manage these dotfiles using standard Git commands. This is because `yadm` relies entirely on a standard bare Git repository.

1. **Clone the bare repository:**
   ```bash
   git clone --bare git@github.com:mabino/dotfiles.git $HOME/.yadm/repo.git
   ```
2. **Alias a Git command for the dotfiles:**
   ```bash
   alias config='/usr/bin/git --git-dir=$HOME/.yadm/repo.git/ --work-tree=$HOME'
   ```
3. **Checkout the files:**
   ```bash
   config checkout
   ```
   *(Note: You might encounter errors if pre-existing files conflict. You can back those up or force the checkout using `config checkout -f`)*
4. **Configure it to ignore untracked files:**
   ```bash
   config config --local status.showUntrackedFiles no
   ```
