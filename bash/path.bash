if [[ "$(uname)" == "Darwin" ]]; then
	### Heroku Toolbelt
	PATH="/usr/local/heroku/bin:$PATH"

	# Adobe Flex SDK
	PATH="~/Code/flex_sdk_4.6/bin:$PATH"

	# Ensure /usr/local/bin before /usr/bin for Homebrew
	PATH="/usr/local/bin:/usr/local/sbin:$PATH"

	# Golang
	PATH="${GOPATH//://bin:}/bin:$PATH"

	# AEM stuffs
	PATH="$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH"
fi

# Put ~/bin before everything
PATH="~/bin:$PATH"

# Add RVM to PATH for scripting.
PATH="$PATH:~/.rvm/bin"

export PATH
