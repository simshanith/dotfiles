# pipe markdown to screen as pretty-printed, syntax highlighted HTML
markdown() {
  pd mode:"beautify" readmethod:"screen" source:"`md $1`" |
  pygmentize -l html
}


# html css js csv beautification via prettydiff
beautify() {
  local SOURCE=`realpath "$1"`
  [ -r "$SOURCE" ] && pd mode:'beautify' readmethod:'filescreen' source:"$SOURCE"
}

# Change directory to the current Finder directory
# http://apple.stackexchange.com/a/96810/52388
cdf() {
    target=`osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as text)'`
    if [ "$target" != "" ]; then
        cd "$target"; pwd
    else
        echo 'No Finder window found' >&2
    fi
}

# open man pages in Preview.app
if [ -d "/Applications/Preview.app" ]
then
  pman () {
    man -t "$@" |
    ( which ps2pdf &> /dev/null && ps2pdf - - || cat) |
    open -f -a /Applications/Preview.app
  }
fi

# Load nvm into a shell session *as a function*
[[ -s $HOME/.nvm/nvm.sh ]] && source $HOME/.nvm/nvm.sh

# Load RVM into a shell session *as a function*
[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm
