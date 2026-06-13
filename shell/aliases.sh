# ~/.aliases
# Shell aliases

# ============================================================
# ls (GNU coreutils via Homebrew)
# ============================================================
if command -v gls &>/dev/null; then
    alias ls='gls --color=auto -p -F'
else
    alias ls='ls -GFh'  # macOS fallback
fi
alias la='ls -A'
alias ll='ls -lh'
alias lla='ll -A'
alias all='lla'

# ============================================================
# Navigation
# ============================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# ============================================================
# Color output
# ============================================================
alias grep='grep --color=auto'
alias rg='rg --smart-case'
alias less='less -R'
alias more='more -R'

# ============================================================
# Safety
# ============================================================
alias please='sudo'

# ============================================================
# Editors
# ============================================================
alias emacs='emacs --no-splash -nw'

# ============================================================
# File utilities
# ============================================================
# Use GNU readlink to determine absolute filepaths
command -v greadlink &>/dev/null && alias realpath='greadlink -f'

# ============================================================
# Git shortcuts (supplements .gitconfig aliases)
# ============================================================
alias g='git'
alias gs='git status -s'
alias gd='git diff'

# ============================================================
# Python
# ============================================================
alias jsontool='python3 -m json.tool'

# ============================================================
# Misc
# ============================================================
# http://xkcd.com/530/
alias stfu="osascript -e 'set volume output muted true'"
alias pumpitup="osascript -e 'set volume 10'"

# open all merge conflicts or currently changed files in editor
alias fixchanges="git diff --name-only | uniq | xargs \$EDITOR"
