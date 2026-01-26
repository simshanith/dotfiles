# dircolors setup
# requires GNU `dircolors` + `ls`
# `brew install coreutils`

# https://github.com/seebi/dircolors-solarized
if command -v gdircolors &>/dev/null; then
    eval "$(gdircolors ~/.dircolors)"
elif command -v dircolors &>/dev/null; then
    eval "$(dircolors ~/.dircolors)"
fi
