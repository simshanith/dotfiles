USE_GNU_LS=true

if $USE_GNU_LS ; then
	if [[ "$(uname)" == "Darwin" ]]; then
		alias ls="gls --color=auto -p -F"
	else
		alias ls="ls --color=auto -p -F"
	fi
else
	alias ls="ls -GFH"
fi

alias la="ls -A"
alias ll="ls -lHh"
alias lla="ll -A"
alias all="lla"


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

alias emacs="TERM=xterm-256color emacs --no-splash -nw"

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

# alias t to todo.txt CLI
alias t='todo'

# https://github.com/paulirish/dotfiles/blob/master/.aliases
# `cat` with beautiful colors. requires Pygments installed.
alias c='pygmentize -O style=monokai -f console256 -g'

# http://xkcd.com/530/
alias stfu="osascript -e 'set volume output muted true'"
alias pumpitup="osascript -e 'set volume 10'"
alias hax="growl '31337 hax WTF'; eightbit;"

# open all merge conflicts or currently changed files in sublime text
alias fixchanges="git diff --name-only | uniq | xargs subl"
