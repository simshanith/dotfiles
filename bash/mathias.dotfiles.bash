# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.

# These are symlinked with fresh.
for file in ~/.{exports,path,aliases,functions,bash_prompt,extra,iterm2_shell_integration.bash}; do
    [ -r "$file" ] && source "$file"
done
unset file
