# http://kmkeen.com/awk-music/
eightbit() {
  awk 'function wl() {
        rate=64000;
        return (rate/160)*(0.87055^(int(rand()*10)))};
    BEGIN {
        srand();
        wla=wl();
        while(1) {
            wlb=wla;
            wla=wl();
            if (wla==wlb)
                {wla*=2;};
            d=(rand()*10+5)*rate/4;
            a=b=0; c=128;
            ca=40/wla; cb=20/wlb;
            de=rate/10; di=0;
            for (i=0;i<d;i++) {
                a++; b++; di++; c+=ca+cb;
                if (a>wla)
                    {a=0; ca*=-1};
                if (b>wlb)
                    {b=0; cb*=-1};
                if (di>de)
                    {di=0; ca*=0.9; cb*=0.9};
                printf("%c",c)};
            c=int(c);
            while(c!=128) {
                c<128?c++:c--;
                printf("%c",c)};};}' |
  sox -t raw -r 64k -c 1 -e unsigned -b 8 - -d
}


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

# Create a new directory and enter it
function mkd() {
    mkdir -p "$@" && cd "$@"
}

### iTerm2 utils
if [[ "$TERM_PROGRAM" == 'iTerm.app' ]]
then
    nametab () { 
        if [ -z "$1" ]; then
            echo "Usage:"
            echo "\`nametab workspace\`"
            echo "Sets the tab's namespace in iTerm using escape sequence."
        else
            echo -e $'\033];'${*}'\007' ; return ;
        fi
    }

    # send growl messages
    # http://aming-blog.blogspot.com/2011/01/growl-notification-from-iterm-2.html
    # requires growl http://growl.info/
    growl() { echo -e $'\e]9;'${*}'\007' ; return ; }
fi

# http://xkcd.com/530/
hello () {
    osascript -e 'say "Hello '$1'"';
}

# git log with per-commit cmd-clickable GitHub URLs (iTerm)
function gf() {
  local remote="$(git remote -v | awk '/^origin.*\(push\)$/ {print $2}')"
  [[ "$remote" ]] || return
  local user_repo="$(echo "$remote" | perl -pe 's/.*://;s/\.git$//')"
  git log $* --name-status --color | awk "$(cat <<AWK
    /^.*commit [0-9a-f]{40}/ {sha=substr(\$2,1,7)}
    /^[MA]\t/ {printf "%s\thttps://github.com/$user_repo/blob/%s/%s\n", \$1, sha, \$2; next}
    /.*/ {print \$0}
AWK
  )" | less -F
}

# Start an HTTP server from a directory, optionally specifying the port
function server() {
    local port="${1:-8000}"
    open "http://localhost:${port}/"
    # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
    # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
    python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
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

λ () {
    fortune | cowsay -f tux -W 50 | lolcat -p 2
}

# Load nvm into a shell session *as a function*
[[ -s $HOME/.nvm/nvm.sh ]] && source $HOME/.nvm/nvm.sh

# Load RVM into a shell session *as a function*
#[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm
