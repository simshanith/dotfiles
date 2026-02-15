# ~/.zprofile
# Login shell configuration (sourced by non-interactive shells, IDEs like WebStorm)

eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# mise shims (makes node/etc visible to IDEs and non-interactive shells)
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

# Added by Toolbox App
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
