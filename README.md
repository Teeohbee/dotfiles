# dotfiles

Personal dev environment setup for macOS.

## Install

```bash
git clone git@github.com:Teeohbee/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

The install script will:
- Install Homebrew, Oh My Zsh, nvm, Node LTS, and Claude Code if not present
- Install packages from the Brewfile
- Create `~/Dev`
- Symlink config files into place (backing up any existing files)

## What's included

| Directory | What |
|-----------|------|
| `shell/` | zshrc (Oh My Zsh, aliases, rbenv, nvm), zprofile |
| `git/` | gitconfig (aliases, LFS, default branch), global ignore |
| `ghostty/` | JetBrains Mono, Monokai Pro |
| `claude/` | CLAUDE.md, settings, skills (autoskill, interactive-learning) |
| `Brewfile` | Homebrew packages and casks |

## After install

1. Generate SSH key: `ssh-keygen -t ed25519 -C "your-email"`
2. Add to GitHub: `gh ssh-key add ~/.ssh/id_ed25519.pub`
3. Set git email: `git config --global user.email "your-email"`
4. Install Claude Code plugins: superpowers, playwright
5. Install Monokai Pro theme in Zed and Ghostty

## Work machine

The zshrc sources `~/.zshrc.work` if it exists - put machine-specific config there.
