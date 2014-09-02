### Heroku Toolbelt
PATH="/usr/local/heroku/bin:$PATH"

# Add rvm & ruby gems to the path
PATH="$PATH:~/.gem/ruby/1.8/bin:$HOME/.rvm/bin"

# Ensure /usr/local/bin before /usr/bin for Homebrew
PATH="/usr/local/bin:/usr/local/sbin:$PATH"

# Put ~/bin before everything
PATH="~/bin:$PATH"

# AEM stuffs
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.7.0_67.jdk/Contents/Home"
export MAVEN_HOME="/usr/local/Cellar/maven/3.2.3/libexec"
export MAVEN_OPTS="-Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true"

PATH="$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH"

export PATH
