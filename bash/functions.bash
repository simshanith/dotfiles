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

nametab () { 
    if [ -z "$1" ]; then
        echo "Usage:"
        echo "\`nametab workspace\`"
        echo "Sets the tab's namespace in iTerm using escape sequence."
    else
        echo -e "\033];$1\007"
    fi
}

# send growl messages
# http://aming-blog.blogspot.com/2011/01/growl-notification-from-iterm-2.html
# requires growl & iTerm http://growl.info/
if [[ "$TERM_PROGRAM" == 'iTerm.app' ]]; then
    growl() { echo -e $'\e]9;'${*}'\007' ; return ; }
fi

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
