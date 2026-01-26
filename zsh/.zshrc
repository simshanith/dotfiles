# ~/.zshrc
# Zsh configuration for macOS (Apple Silicon)
# Managed via Fresh from ~/.dotfiles

# ============================================================
# Fresh shell manager
# ============================================================
source ~/.fresh/build/shell.sh

# ============================================================
# Cross-shell configs (managed by Fresh)
# ============================================================
for file in ~/.{exports,path,aliases,functions,extra}; do
    [[ -r "$file" ]] && source "$file"
done
unset file

# ============================================================
# Completions
# ============================================================
# Homebrew completions (Apple Silicon path) - must be before compinit
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

autoload -Uz compinit
# Rebuild completion cache once per day
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# ============================================================
# Prompt: Starship
# ============================================================
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# ============================================================
# Modern CLI tools
# ============================================================
# zoxide - smart directory jumping (replaces fasd/z/autojump)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# fzf - fuzzy finder
if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
fi

# zsh-history-substring-search
if [[ -f "$(brew --prefix 2>/dev/null)/share/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
fi

# ============================================================
# Key bindings
# ============================================================
# Word navigation (Option + arrow keys in iTerm2)
bindkey "[D" backward-word    # opt-left
bindkey "[C" forward-word     # opt-right

# History search with up/down arrows (if substring-search loaded)
if (( $+functions[history-substring-search-up] )); then
    bindkey "^[[A" history-substring-search-up
    bindkey "^[[B" history-substring-search-down
fi

# ============================================================
# Colors
# ============================================================
[[ -f ~/.dircolors ]] && eval "$(gdircolors ~/.dircolors)"

# ============================================================
# Tool integrations
# ============================================================
# iTerm2 shell integration
[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && \
    source "${HOME}/.iterm2_shell_integration.zsh"

# nvm (Node version manager)
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# bun
if [[ -d "${HOME}/.bun" ]]; then
    export BUN_INSTALL="${HOME}/.bun"
    [[ -s "${BUN_INSTALL}/_bun" ]] && source "${BUN_INSTALL}/_bun"
    export PATH="${BUN_INSTALL}/bin:${PATH}"
fi

# thefuck (if installed)
command -v thefuck &>/dev/null && eval "$(thefuck --alias)"

# ============================================================
# Local overrides (not in git)
# ============================================================
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local
