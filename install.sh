#!/bin/bash
# Dotfiles bootstrap script
# Assumes: macOS, Apple Silicon, zsh
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
echo "=== Dotfiles Installation ==="
echo "Source: $DOTFILES"

# Homebrew
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Packages
echo "Installing packages..."
brew bundle --file="$DOTFILES/Brewfile" || true

# Backup existing configs
backup_dir="$DOTFILES/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"
for f in .zshrc .exports .path .aliases .functions .tmux.conf .inputrc; do
    if [[ -f "$HOME/$f" && ! -L "$HOME/$f" ]]; then
        echo "Backing up ~/$f"
        mv "$HOME/$f" "$backup_dir/"
    fi
done

# Backup starship config if it exists
if [[ -f "$HOME/.config/starship.toml" && ! -L "$HOME/.config/starship.toml" ]]; then
    echo "Backing up ~/.config/starship.toml"
    mv "$HOME/.config/starship.toml" "$backup_dir/"
fi

# Create .gituserconfig if it doesn't exist
if [[ ! -e "$DOTFILES/git/.gituserconfig" ]]; then
    cat > "$DOTFILES/git/.gituserconfig" << 'EOF'
# User-specific git settings (not committed to repo)
# Example:
# [user]
#   name = John Doe
#   email = jdoe@example.com
EOF
    echo "Git user config initialized. Please edit $DOTFILES/git/.gituserconfig"
fi

# Fresh shell manager
if [[ ! -d "$HOME/.fresh" ]]; then
    echo "Installing Fresh..."
    bash -c "$(curl -sL https://get.freshshell.com)"
else
    echo "Updating Fresh..."
    fresh update || true
fi

# Source fresh to make the command available
source "$HOME/.fresh/build/shell.sh"

# Link configs
cp "$DOTFILES/.freshrc" "$HOME/.freshrc"
fresh install

# Configure git to include fresh-managed defaults
# This allows git config --global to work while preserving fresh defaults
FRESH_GITCONFIG="$HOME/.fresh/build/gitconfig"
if [[ -f "$FRESH_GITCONFIG" ]]; then
    if ! git config --global --get-all include.path 2>/dev/null | grep -qF "$FRESH_GITCONFIG"; then
        echo "Configuring git to include fresh defaults..."
        git config --global include.path "$FRESH_GITCONFIG"
    fi
fi

# mise config:
#   - conf.d/fresh.toml is symlinked by fresh (always-synced baseline)
#   - config.toml + config.local.toml are copied once (machine-mutable)
mkdir -p "$HOME/.config/mise/conf.d"
if [[ ! -f "$HOME/.config/mise/config.toml" ]]; then
    cp "$DOTFILES/mise/config.toml" "$HOME/.config/mise/config.toml"
    echo "mise config.toml copied. Edit ~/.config/mise/config.toml for machine-specific tools."
fi
if [[ ! -f "$HOME/.config/mise/config.local.toml" ]]; then
    cp "$DOTFILES/mise/config.local.toml" "$HOME/.config/mise/config.local.toml"
    echo "mise config.local.toml template copied."
fi

# iTerm2 shell integration
if [[ ! -f "$HOME/.iterm2_shell_integration.zsh" ]]; then
    echo "Installing iTerm2 shell integration..."
    curl -L https://iterm2.com/shell_integration/zsh -o "$HOME/.iterm2_shell_integration.zsh"
fi

echo ""
echo "=== Done! ==="
echo "Restart terminal or run: exec zsh"
