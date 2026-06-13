# Brewfile
# Install: brew bundle
# Cleanup: brew bundle cleanup --force
#
# Most CLI tools live in ~/.config/mise/config.toml now.
# This file is for: shells, system PATH replacements, GUI apps,
# and tools that need brew's macOS integration (taps, terminfo, keychain).
tap "d12frosted/emacs-plus"

# Shell
brew "bash"
brew "zsh"
brew "zsh-history-substring-search"

# Core utilities (system PATH replacements)
brew "coreutils"
brew "gnu-sed"
brew "grep"
brew "ssh-copy-id"

# Git (kept in brew: bootstrap dependency, macOS keychain integration)
brew "git"

# Editors
brew "emacs-plus@30"

# Terminal (kept in brew: terminfo + tmux-256color)
brew "tmux"

# tree: GNU tree (not in mise's short-name registry)
brew "tree"

# tig: ncurses git browser (not in mise's short-name registry)
brew "tig"

# Runtime management (bootstrap)
brew "mise"

# Misc
# thefuck dropped — replaced by pay-respects (mise-managed Rust port)
brew "fortune"
brew "cowsay"
brew "lolcat"
brew "sox"

# Casks
cask "1password"
cask "1password-cli"
cask "ghostty"
cask "google-chrome"
cask "iterm2"
cask "localsend"
cask "tailscale-app"

# Fonts
cask "font-symbols-only-nerd-font"
