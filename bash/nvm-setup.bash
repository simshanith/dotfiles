# Load nvm into a shell session *as a function*
[[ -n "$(type -t nvm)" ]] && [[ -s $HOME/.nvm/nvm.sh ]] && source $HOME/.nvm/nvm.sh
# Some NVM integration
nvm use default --silent;
