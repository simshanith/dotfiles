#!/usr/bin/env bash

# bootstrap the configuration
# requires git

# backup configs
for dotfile in ~/.{bash_profile,bashrc,freshrc,gitconfig}; do
  [ -r "$dotfile" ] && mv -vf $dotfile ~/.dotfiles/backups/
done
unset dotfile

# copy .freshrc to ~
cp -vf ~/.dotfiles/.freshrc ~

# copy bin/symlinks to ~/bin
cp -R ~/.dotfiles/bin/symlinks/* ~/bin/

if [ -e ~/.dotfiles/.gituserconfig ]; then
  echo "Git user config already exists."
else
  touch ~/.dotfiles/.gituserconfig
  echo "### user specific settings" >> ~/.dotfiles/.gituserconfig
  echo "### e.g." >> ~/.dotfiles/.gituserconfig
  echo "# [user]" >> ~/.dotfiles/.gituserconfig
  echo "#   name = John Doe" >> ~/.dotfiles/.gituserconfig
  echo "#   email = jdoe@example.com" >> ~/.dotfiles/.gituserconfig

  echo "Git user config intialized. Please edit and re-run \`fresh\`."
fi

# install fresh or run for re-fresh
if [[ -z `which fresh` ]]; then
  bash -c "`curl -sL get.freshshell.com`"
else
  fresh
fi

# source it
if [[ -z "$SIM_DOTFILES_SETUP" ]]; then
  [ -r "~/.bash_profile" ] && source ~/.bash_profile
fi

if [[ -n "$SIM_DOTFILES_SETUP" ]]; then
  echo "All done! Your prompt should be updated and you are now using Fresh."
fi
