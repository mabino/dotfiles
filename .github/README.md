# My Dotfiles

These are my personal dotfiles, managed seamlessly with [yadm](https://yadm.io/) (Yet Another Dotfiles Manager).

## Why yadm?

I chose `yadm` over traditional symlink-based managers (like GNU Stow) or bulky frameworks for several reasons:

1. **Git Native:** `yadm` is essentially a wrapper around standard Git, operating directly on a bare repository. There are no proprietary formats or complex directory structures. If you know Git, you know `yadm`.
2. **No Symlink Mess:** Files live exactly where they are supposed to be. No cluttered source directories and confusing symlinks.
3. **Built-in Extras:** It seamlessly supports file encryption (using GnuPG, age, or transcrypt), templating (for OS-specific differences), and a bootstrap script to run post-installation tasks.

## Deployment Guide

Deploying these dotfiles to a new machine is incredibly straightforward.

### Prerequisites

Ensure you have Git and [yadm](https://yadm.io/docs/install) installed. On macOS, you can install yadm via Homebrew:

```bash
brew install yadm
```

### Installation

1. Clone the repository and apply the dotfiles in one command:
   ```bash
   yadm clone <your-repository-url>
   ```
2. (Optional) If the repository includes a bootstrap script (`~/.config/yadm/bootstrap`), `yadm clone` will prompt you to run it. If you want to run it manually later:
   ```bash
   yadm bootstrap
   ```
3. (Optional) Decrypt sensitive files if configured:
   ```bash
   yadm decrypt
   ```

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

Now you can use the `config` alias exactly as you would use `git` (or `yadm`) to manage your files: `config status`, `config add <file>`, `config commit`, etc.
