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

# Maven & Java AEM stuffs
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.7.0_67.jdk/Contents/Home"
export MAVEN_HOME="/usr/local/Cellar/maven/3.2.3/libexec"
export MAVEN_OPTS="-Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true"

# Set my editor and git editor
export EDITOR="subl -w"
export GIT_EDITOR="subl -w"
export SVN_EDITOR="subl -w"
# GNU Emacs GUI
export EMACS_APP="/Applications/Emacs.app/Contents/MacOS/Emacs"

# Handy Dropbox reference.
export DROPBOX="$HOME/Dropbox"

# Golang
export GOPATH="$HOME/golang"

# Google Chrome via Caskroom.
export CHROME_BIN="$HOME/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Firefox via Caskroom (for SlimerJS)
export SLIMERJSLAUNCHER="$HOME/Applications/Firefox.app/Contents/MacOS/firefox"


# pkg-config for node-canvas et al.
# <https://github.com/Automattic/node-canvas/wiki/installation---osx>
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/opt/X11/lib/pkgconfig

export SIM_DOTFILES_SETUP='oooohyeah'
