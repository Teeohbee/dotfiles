#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

info() { printf "\033[0;34m[info]\033[0m %s\n" "$1"; }
warn() { printf "\033[0;33m[warn]\033[0m %s\n" "$1"; }
ok()   { printf "\033[0;32m[ok]\033[0m   %s\n" "$1"; }

backup_and_link() {
  local src="$1"
  local dest="$2"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      ok "$dest already linked"
      return
    fi
    mkdir -p "$BACKUP_DIR"
    mv "$dest" "$BACKUP_DIR/$(basename "$dest")"
    warn "backed up existing $dest"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  ok "linked $dest -> $src"
}

echo ""
echo "=== Dotfiles installer ==="
echo "Source: $DOTFILES_DIR"
echo ""

# --- Homebrew ---
if command -v brew &>/dev/null; then
  ok "Homebrew already installed"
else
  info "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "Homebrew installed"
fi

echo ""
read -p "Install Homebrew packages from Brewfile? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  brew bundle --file="$DOTFILES_DIR/Brewfile"
  ok "Homebrew packages installed"
else
  info "Skipped. Run 'brew bundle --file=$DOTFILES_DIR/Brewfile' later."
fi

# --- Oh My Zsh ---
echo ""
if [ -d "$HOME/.oh-my-zsh" ]; then
  ok "Oh My Zsh already installed"
else
  info "Installing Oh My Zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  ok "Oh My Zsh installed"
fi

# --- nvm ---
echo ""
if [ -d "$HOME/.nvm" ]; then
  ok "nvm already installed"
else
  info "Installing nvm"
  PROFILE=/dev/null bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh)"
  ok "nvm installed"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

info "Installing Node LTS via nvm"
nvm install --lts
ok "Node $(node --version) installed"

# --- Claude Code ---
echo ""
if command -v claude &>/dev/null; then
  ok "Claude Code already installed"
else
  info "Installing Claude Code"
  npm install -g @anthropic-ai/claude-code
  ok "Claude Code installed"
fi

# --- Directories ---
echo ""
info "Directories"
mkdir -p "$HOME/code"
ok "~/code created"

# --- Shell ---
echo ""
info "Shell config"
backup_and_link "$DOTFILES_DIR/shell/zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/shell/zprofile" "$HOME/.zprofile"

# --- SSH ---
info "SSH config"
backup_and_link "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"

# --- Git ---
info "Git config"
backup_and_link "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
backup_and_link "$DOTFILES_DIR/git/global_ignore" "$HOME/.global_ignore"

# --- Ghostty ---
info "Ghostty config"
backup_and_link "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

# --- Claude Code ---
info "Claude Code config"
backup_and_link "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
backup_and_link "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"

# Skills
backup_and_link "$DOTFILES_DIR/claude/skills/autoskill" "$HOME/.claude/skills/autoskill"
backup_and_link "$DOTFILES_DIR/claude/skills/interactive-learning" "$HOME/.claude/skills/interactive-learning"

# --- Summary ---
echo ""
echo "=== Done ==="
echo ""
if [ -d "$BACKUP_DIR" ]; then
  echo "Backups saved to: $BACKUP_DIR"
fi
echo ""
echo "Remaining manual steps:"
echo "  1. Generate SSH key: ssh-keygen -t ed25519 -C \"your-email@example.com\""
echo "  2. Load key into Keychain: ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
echo "  3. Add SSH key to GitHub: gh ssh-key add ~/.ssh/id_ed25519.pub"
echo "  4. Set git email: git config --global user.email \"your-email@example.com\""
echo "  5. Install Claude Code plugins: superpowers, playwright"
echo "  6. Install Monokai Pro theme in Zed and Ghostty"
echo ""
