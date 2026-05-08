# dotfiles

Personal dev environment setup for macOS.

## Fresh machine setup

1. Install Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```

2. Clone and run the installer:
   ```bash
   git clone https://github.com/Teeohbee/dotfiles.git ~/.dotfiles
   ~/.dotfiles/install.sh
   ```

3. Set up SSH and git identity:
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   gh ssh-key add ~/.ssh/id_ed25519.pub
   git config --global user.email "your-email@example.com"
   ```

4. Switch the dotfiles remote to SSH:
   ```bash
   cd ~/.dotfiles
   git remote set-url origin git@github.com:Teeohbee/dotfiles.git
   ```

5. Install Claude Code plugins: superpowers, playwright

6. Install Monokai Pro theme in Zed and Ghostty

## What the installer does

- Installs Homebrew, Oh My Zsh, nvm, Node LTS, and Claude Code
- Installs packages from the Brewfile
- Creates `~/code`
- Symlinks config files into place (backing up any existing files)

## What's included

See [APPLICATIONS.md](APPLICATIONS.md) for details on each app, why it's included, and open-source credentials.

| Directory | What |
|-----------|------|
| `shell/` | zshrc (Oh My Zsh, aliases, rbenv, nvm), zprofile |
| `git/` | gitconfig (aliases, LFS, default branch), global ignore |
| `ghostty/` | JetBrains Mono, Monokai Pro |
| `claude/` | CLAUDE.md, settings, skills (autoskill, interactive-learning) |
| `Brewfile` | Homebrew packages and casks |

## Work machine

The zshrc sources `~/.zshrc.work` if it exists - put machine-specific config there.
