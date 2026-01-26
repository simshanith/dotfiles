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

# Bun
if [[ -d "$HOME/.bun" ]]; then
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# ============================================================
# Container tools
# ============================================================
# Rancher Desktop
[[ -d "$HOME/.rd/bin" ]] && export PATH="$HOME/.rd/bin:$PATH"
