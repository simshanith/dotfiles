if [[ "$(uname)" == "Darwin" ]]; then
	### Heroku Toolbelt
	PATH="/usr/local/heroku/bin:$PATH"

	# Add rvm & ruby gems to the path
	#PATH="$PATH:~/.gem/ruby/1.8/bin:$HOME/.rvm/bin"

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

export PATH
