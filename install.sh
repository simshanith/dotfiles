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
for f in .zshrc .exports .path .aliases .functions .gitconfig .tmux.conf .inputrc; do
    if [[ -f "$HOME/$f" && ! -L "$HOME/$f" ]]; then
        echo "Backing up ~/$f"
        mv "$HOME/$f" "$backup_dir/"
    fi
done

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

# Link configs
cp "$DOTFILES/.freshrc" "$HOME/.freshrc"
fresh install

# iTerm2 shell integration
if [[ ! -f "$HOME/.iterm2_shell_integration.zsh" ]]; then
    echo "Installing iTerm2 shell integration..."
    curl -L https://iterm2.com/shell_integration/zsh -o "$HOME/.iterm2_shell_integration.zsh"
fi

echo ""
echo "=== Done! ==="
echo "Restart terminal or run: exec zsh"
