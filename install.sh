#!/bin/bash
# Dotfiles bootstrap — macOS, Apple Silicon, zsh.
# Idempotent; safe to re-run. State is managed by chezmoi (+ mise for tooling).
#
# Three ways to run, all supported:
#   - Already cloned (or via Coder, which clones then runs this script):
#         ~/.dotfiles/install.sh        # uses this script's own dir as the repo
#   - Remote one-liner on a fresh machine (self-clones to ~/.dotfiles):
#         bash -c "$(curl -fsSL https://raw.githubusercontent.com/simshanith/dotfiles/main/install.sh)"
set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/simshanith/dotfiles.git}"

# Locate the repo. Prefer the directory this script lives in — that handles a
# normal clone AND Coder (which clones to its own path, e.g. ~/dotfiles, then
# runs the install script from there). When piped via curl|bash there's no
# script file, so fall back to ~/.dotfiles and self-clone below.
if src="${BASH_SOURCE[0]:-}" && [ -n "$src" ] && [ -f "$src" ]; then
    DOTFILES="$(cd "$(dirname "$src")" && pwd)"
else
    DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
fi

echo "=== Dotfiles Installation ==="
echo "Source: $DOTFILES"

# 1. Homebrew — bootstrap dependency for mise + GUI apps. Its installer also
#    pulls in the Xcode Command Line Tools, which is how a truly fresh Mac gets
#    `git` for the clone step below.
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

# 2. Clone the repo if it isn't already present (the curl|bash path). When this
#    script was run from a checkout, the repo is obviously already here.
if [ ! -f "$DOTFILES/install.sh" ]; then
    echo "Cloning $REPO -> $DOTFILES ..."
    command -v git &>/dev/null || xcode-select --install || true
    git clone "$REPO" "$DOTFILES"
fi

# 3. Brew packages — shells, GUI casks, terminfo, and tools that need brew's
#    macOS integration. The CLI toolchain itself lives in mise (see Brewfile).
echo "Installing Homebrew packages..."
brew bundle --file="$DOTFILES/Brewfile" || true

# 4. chezmoi takes over: symlink dotfiles, render templates, run run_once_ scripts.
#    Bootstrap chicken-and-egg: chezmoi is in the mise baseline, but that baseline
#    (~/.config/mise/conf.d/fresh.toml) isn't symlinked until chezmoi applies. So
#    run chezmoi on-demand via `mise exec` for the first apply. First run prompts
#    for name/email/work/machine (see .chezmoi.toml.tmpl); sourceDir is recorded
#    as $DOTFILES, so this works from any clone location.
eval "$(mise activate bash)"
mise exec chezmoi@latest -- chezmoi init --source="$DOTFILES" --apply

# 5. Now the mise baseline IS in place — install the full toolchain (node, rust,
#    starship, chezmoi itself, ...). Subsequent updates: `mise install` / `mise up`.
mise install -y

echo ""
echo "=== Done! ==="
echo "Restart shell:  exec zsh"
echo "Verify:         chezmoi status   (should be empty)"
