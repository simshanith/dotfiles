#!/bin/bash
# Dotfiles bootstrap — macOS, Apple Silicon, zsh.
# Idempotent; safe to re-run. State is managed by chezmoi (+ mise for tooling).
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
echo "=== Dotfiles Installation ==="
echo "Source: $DOTFILES"

# 1. Homebrew — bootstrap dependency for mise + GUI apps on a fresh machine.
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

# 2. Brew packages — shells, GUI casks, terminfo, and tools that need brew's
#    macOS integration. The CLI toolchain itself lives in mise (see Brewfile).
echo "Installing Homebrew packages..."
brew bundle --file="$DOTFILES/Brewfile" || true

# 3. chezmoi takes over: symlink dotfiles, render templates, run run_once_ scripts.
#    Bootstrap chicken-and-egg: chezmoi is in the mise baseline, but that baseline
#    (~/.config/mise/conf.d/fresh.toml) isn't symlinked until chezmoi applies. So
#    run chezmoi on-demand via `mise exec` for the first apply. First run prompts
#    for name/email/work/machine (see .chezmoi.toml.tmpl).
eval "$(mise activate bash)"
mise exec chezmoi@latest -- chezmoi init --source="$DOTFILES" --apply

# 4. Now the mise baseline IS in place — install the full toolchain (node, rust,
#    starship, chezmoi itself, ...). Subsequent updates: `mise install` / `mise up`.
mise install -y

echo ""
echo "=== Done! ==="
echo "Restart shell:  exec zsh"
echo "Verify:         chezmoi status   (should be empty)"
