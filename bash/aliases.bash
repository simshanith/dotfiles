# BSD ls file listing
# G for color
# F for non-file identification
# A for hidden files & dirs
# l for expanded listing
# H for following symlinks
alias ls='ls -GF'
alias la='ls -GAF'
alias ll='ls -GFlh'
alias lla='ls -GFalh'
alias all='lla'
alias lsnpm='echo $NPM_GLOBAL_PACKAGES; ls $NPM_GLOBAL_PACKAGES'


# less & grep with ANSI colors
alias less='less --RAW-CONTROL-CHARS'
alias more='more --RAW-CONTROL-CHARS'
alias grep='grep --color=auto'
# be nice
alias please=sudo
alias hosts='please $EDITOR /etc/hosts' 

# folder jumpin
alias ..='cd ..'         # Go up one directory
alias ...='cd ../..'     # Go up two directories
alias ....='cd ../../..' # Go up three directories
alias -- -='cd -'        # Go back

# File editing
# ~/bin/subl (set in exports)
alias subl="subl -w"
alias bgsubl="forever start -m 1 -c subl"
alias edit="subl"

# git hub
# http://hub.github.com/
# alias git=hub

# fasd shortcuts
alias fe="f -e $EDITOR"
alias ae="a -e $EDITOR"
alias se="s -e $EDITOR"
alias de="d -e $EDITOR"
# interactive mode: display list then open with editor
alias fei="f -i -e $EDITOR"
alias aei="a -i -e $EDITOR"
alias sei="s -i -e $EDITOR"
alias dei="d -i -e $EDITOR"

alias fie="fei"
alias aie="aei"
alias sie="sei"
alias die="dei"

# GNU Emacs.app
alias em="$EMACS_APP"
alias fem="f -e $EMACS_APP"
alias aem="a -e $EMACS_APP"
alias sem="s -e $EMACS_APP"
alias dem="d -e $EMACS_APP"

alias feim="f -i -e $EMACS_APP"
alias aeim="a -i -e $EMACS_APP"
alias seim="s -i -e $EMACS_APP"
alias deim="d -i -e $EMACS_APP"

alias fiem="feim"
alias aiem="aeim"
alias siem="seim"
alias diem="deim"

# Use GNU readlink to determine absolute filepaths
alias realpath='greadlink -f'

# alias "http" to python SimpleHTTPServer function
alias http='server'

# alias "jsontool" to json.tool
alias jsontool='python -m json.tool'

# alias md to marked (node markdown parser)
alias md='marked --smart-lists'

# alias mou to Mou app
alias mou='open -a Mou'

# alias nw to node-webkit app
# alias nw='~/Applications/node-webkit.app/Contents/MacOS/node-webkit'

# alias prettydiff
alias pd='node $NPM_GLOBAL_PACKAGES/prettydiff/api/node-local.js'

# alias t to todo.txt CLI
alias t='todo'

# https://github.com/paulirish/dotfiles/blob/master/.aliases
# `cat` with beautiful colors. requires Pygments installed.
alias c='pygmentize -O style=monokai -f console256 -g'

# http://xkcd.com/530/
alias stfu="osascript -e 'set volume output muted true'"
alias pumpitup="osascript -e 'set volume 10'"
alias hax="growlnotify -a 'Activity Monitor' 'System error' -m 'WTF R U DOIN';"
