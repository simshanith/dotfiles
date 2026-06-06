# dircolors setup
# requires GNU `dircolors` + `ls`
# `brew install coreutils`

# Solarized theme vendored from https://github.com/seebi/dircolors-solarized
: "${DOTFILES:=$HOME/.dotfiles}"
_dircolors_db="$DOTFILES/shell/dircolors.ansi-universal"
if command -v gdircolors &>/dev/null; then
    eval "$(gdircolors "$_dircolors_db")"
elif command -v dircolors &>/dev/null; then
    eval "$(dircolors "$_dircolors_db")"
fi
unset _dircolors_db
