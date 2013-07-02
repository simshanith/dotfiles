# ls file listing
alias ls='ls -GF'
alias la='ls -GAF'
alias ll='ls -GFalh'

# less with ANSI colors
alias less='less --RAW-CONTROL-CHARS'

# folder jumpin
alias ..='cd ..'         # Go up one directory
alias ...='cd ../..'     # Go up two directories
alias ....='cd ../../..' # Go up three directories
alias -- -='cd -'        # Go back

# file editing
alias edit="$EDITOR"
alias em='open -a emacs'

# alias "http" to SimpleHTTPServer
alias http='python -m SimpleHTTPServer'

# alias markdown to marked (node markdown parser)
alias markdown='marked --smart-lists'

# alias t to todo.txt CLI
alias t='todo'
