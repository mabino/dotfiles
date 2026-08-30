# My Dotfiles

These are my personal dotfiles, managed seamlessly with [yadm](https://yadm.io/) (Yet Another Dotfiles Manager).

## 🚀 Quick Start (Brand New Mac)

On a fresh macOS machine, open Terminal and run the single-command bootstrap:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mabino/dotfiles/main/.local/bin/bootstrap-mac)"
```

Or for a completely non-interactive / silent installation:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mabino/dotfiles/main/.local/bin/bootstrap-mac)" -- --silent
```

### What This Automates:
1. Verifies/installs **Xcode Command Line Tools**.
2. Installs and configures **Homebrew**.
3. Discovers or creates a machine-specific **SSH ED25519 key** and permanently saves its passphrase to the **macOS Keychain** (challenge once per machine).
4. Registers your public key with **GitHub** via `gh` CLI.
5. Clones dotfiles using **yadm** (handling SSH/HTTPS fallback seamlessly).
6. Configures global **Git hooks** and the **Brewfile union merge driver**.
7. Links master **`~/.AGENT.md`** across **Claude**, **Gemini**, and **Copilot**.
8. Installs all packages, CLI tools, and development apps via **`brew bundle --global`**.
9. Initializes **`mise`** runtimes and toolchains.

---

## 🛠 Manual Installation & Management

If you already have Git and `yadm` installed:

```bash
# Clone repository
yadm clone git@github.com:mabino/dotfiles.git

# Run bootstrap at any time to initialize or repair configuration
yadm bootstrap

# Check SSH key status or enroll new keys
ssh-reconcile status
ssh-reconcile enroll
```

---

## Fallback Usage (Without yadm)

If you find yourself on a system where you **cannot** install `yadm`, you can still easily manage these dotfiles using standard Git commands. This is because `yadm` relies entirely on a standard bare Git repository.

1. **Clone the bare repository:**
   ```bash
   git clone --bare <your-repository-url> $HOME/.yadm/repo.git
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
