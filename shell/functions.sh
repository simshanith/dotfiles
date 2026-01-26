# ~/.functions
# Shell functions

# ============================================================
# Directory utilities
# ============================================================

# Create directory and cd into it
mkd() {
    mkdir -p "$@" && cd "$_"
}

# cd to Finder's current directory (macOS)
cdf() {
    local target
    target=$(osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as text)' 2>/dev/null)
    if [[ -n "$target" ]]; then
        cd "$target" && pwd
    else
        echo 'No Finder window found' >&2
        return 1
    fi
}

# ============================================================
# HTTP server (Python 3)
# ============================================================
server() {
    local port="${1:-8000}"
    echo "Starting server at http://localhost:${port}/"
    open "http://localhost:${port}/"
    python3 -m http.server "$port"
}

# ============================================================
# Man pages in Preview.app (macOS)
# ============================================================
if [[ -d "/Applications/Preview.app" ]]; then
    pman() {
        man -t "$@" | open -f -a Preview
    }
fi

# ============================================================
# Git log with GitHub URLs (iTerm2 clickable)
# ============================================================
gf() {
    local remote user_repo
    remote="$(git remote -v | awk '/^origin.*\(push\)$/ {print $2}')"
    [[ -z "$remote" ]] && return 1
    user_repo="$(echo "$remote" | perl -pe 's/.*://;s/\.git$//')"
    git log "$@" --name-status --color | awk "
        /^.*commit [0-9a-f]{40}/ {sha=substr(\$2,1,7)}
        /^[MA]\t/ {printf \"%s\thttps://github.com/$user_repo/blob/%s/%s\n\", \$1, sha, \$2; next}
        /.*/ {print \$0}
    " | less -F
}

# ============================================================
# iTerm2 utilities
# ============================================================
if [[ "$TERM_PROGRAM" == 'iTerm.app' ]]; then
    nametab() {
        [[ -z "$1" ]] && { echo "Usage: nametab <name>"; return 1; }
        echo -ne "\033]0;$*\007"
    }
fi

# ============================================================
# Fun
# ============================================================
fortune_cow() {
    fortune | cowsay -f tux -W 50 | lolcat -p 2
}

# 8-bit music generator (requires sox)
eightbit() {
    awk 'function wl() {
        rate=64000;
        return (rate/160)*(0.87055^(int(rand()*10)))};
    BEGIN {
        srand(); wla=wl();
        while(1) {
            wlb=wla; wla=wl();
            if (wla==wlb) {wla*=2};
            d=(rand()*10+5)*rate/4;
            a=b=0; c=128; ca=40/wla; cb=20/wlb;
            de=rate/10; di=0;
            for (i=0;i<d;i++) {
                a++; b++; di++; c+=ca+cb;
                if (a>wla) {a=0; ca*=-1};
                if (b>wlb) {b=0; cb*=-1};
                if (di>de) {di=0; ca*=0.9; cb*=0.9};
                printf("%c",c)};
            c=int(c);
            while(c!=128) { c<128?c++:c--; printf("%c",c)}}}' |
    sox -t raw -r 64k -c 1 -e unsigned -b 8 - -d
}
