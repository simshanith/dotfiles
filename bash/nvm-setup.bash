# Some NVM integration

alias currentnode='nvm ls current | ack --nocolor "(?P<version>v[\d]*\.[\d]*.[\d]*)" --output "$+{version}"'
export CURRENT_NODE=`currentnode`

# npm global path from current nvm
export NPM_GLOBAL_PACKAGES="$HOME/.nvm/$CURRENT_NODE/lib/node_modules"
