# ~/.exports
# Environment variables (zsh-compatible, macOS/Apple Silicon focused)

# ============================================================
# History (zsh)
# ============================================================
export HISTSIZE=100000
export SAVEHIST=100000
export HISTFILE=~/.zsh_history

setopt EXTENDED_HISTORY          # Timestamp format :start:elapsed:command
setopt INC_APPEND_HISTORY        # Write immediately, not on exit
setopt SHARE_HISTORY             # Share between sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire dupes first
setopt HIST_IGNORE_DUPS          # Don't record immediate dupes
setopt HIST_IGNORE_ALL_DUPS      # Remove older dupe entries
setopt HIST_FIND_NO_DUPS         # Don't show dupes when searching
setopt HIST_IGNORE_SPACE         # Don't record entries starting with space
setopt HIST_SAVE_NO_DUPS         # Don't write dupes to file
setopt HIST_REDUCE_BLANKS        # Remove extra blanks

# ============================================================
# Editor
# ============================================================
export EDITOR="emacs --no-splash -nw"
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"

# ============================================================
# Pager
# ============================================================
export MANPAGER="less -X"
export PAGER="less"
export LESS="-R"

# ============================================================
# Locale
# ============================================================
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ============================================================
# Silence
# ============================================================
unsetopt BEEP

# ============================================================
# macOS / Apple Silicon
# ============================================================
if [[ "$(uname)" == "Darwin" ]]; then
    # Java (use whatever version is installed)
    if [[ -x /usr/libexec/java_home ]]; then
        JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null)" && export JAVA_HOME
    fi

    # Go (modern setup - modules, no GOPATH needed)
    export GOBIN="$HOME/go/bin"

    # Homebrew Cask install location
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"
fi
