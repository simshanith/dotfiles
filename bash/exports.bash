# declare brew bash as shell
export SHELL="/usr/local/bin/bash"

# awesome history tracking
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoredups
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S  "

# Don’t clear the screen after quitting a manual page
export MANPAGER="less -X"

# Your place for hosting Git repos. I use this for private repos.
export GIT_HOSTING='git@bitbucket.org'

# Set my editor and git editor
export EDITOR="subl -w"
export GIT_EDITOR="subl -w"
export SVN_EDITOR="subl -w"
# GNU Emacs GUI
export EMACS_APP="/Applications/Emacs.app/Contents/MacOS/Emacs"

# Handy Dropbox reference.
export DROPBOX="$HOME/Dropbox"

export SIM_DOTFILES_SETUP='oooohyeah'
