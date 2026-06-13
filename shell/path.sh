# ~/.path
# PATH configuration (Apple Silicon focused)

# ============================================================
# Homebrew (Apple Silicon: /opt/homebrew, Intel: /usr/local)
# ============================================================
if [[ -d "/opt/homebrew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d "/usr/local/Homebrew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# ============================================================
# User binaries
# ============================================================
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# ============================================================
# Language-specific
# ============================================================
# Go
[[ -d "$HOME/go/bin" ]] && export PATH="$HOME/go/bin:$PATH"

# Mise shims (non-interactive shell support; mise activate handles interactive)
[[ -d "$HOME/.local/share/mise/shims" ]] && export PATH="$HOME/.local/share/mise/shims:$PATH"

# ============================================================
# Container tools
# ============================================================
# Rancher Desktop
[[ -d "$HOME/.rd/bin" ]] && export PATH="$HOME/.rd/bin:$PATH"
