[dotfiles.github.io](http://dotfiles.github.io/)
[freshshell.com](http://freshshell.com/)

Inspired by (and using some pieces from) [Bash-It](https://github.com/revans/bash-it)

# Customizing the Terminal
###### Mac OS X 10.8.4 Mountain Lion BASH

After watching [Paul Irish's talk from Fluent 2012](http://www.youtube.com/watch?v=f7AU2Ozu8eo) I realized my dotfiles could use some attention. Generally, I throw some scripts in there as needed, but never take the time to figure out a good workflow for managing all the configurations. When I'm coding, I always have a Terminal open. With some fine tuning, the Terminal can offer a lot of power from a very simple interface. When you find your harmonious setup, you're going to want to share it across your machines and have backups.

[Github Dotfiles](http://dotfiles.github.io/) is a community around publically sharing such setups. There's plenty of options and choices to make. This can be overwhelming but there's a few tools that help keep it simple.

I started my customization journey with [`bash-it`](https://github.com/revans/bash-it), an obvious choice given my predisposition for bash (see footnote). Bash-It is a "shameless rippoff of [`oh-my-zsh`](https://github.com/robbyrussell/oh-my-zsh)" that provides a framework for including aliases, plugins, completions, and themes in your configuration. I combed through the files and picked out several features I wanted to keep and use as my own.

While Bash-It provides a nifty framework for bootstrapping its set of customizations, I wanted something more flexible and extensible to manage my setup. I installed [`fresh`](http://freshshell.com/). With fresh, I can include anything from Bash-It's framework _as well as any other Git-hosted code_. So, rather than using Bash-It's bootstrap, I can use fresh's bootstrap to load Bash-It's files. Bash-It mirrors other files, like plugins, from popular shell libraries. With Fresh, I can go straight to the source and avoid the extra overhead of Bash-It.

I have yet to write a proper bootstrap script to get a new machine up and running, but ["Cowboy" Ben Alman](http://benalman.com/) and [Mathias Bynens](http://mathiasbynens.be/) have [some](https://github.com/cowboy/dotfiles/tree/master/init) [pointers](https://github.com/mathiasbynens/dotfiles/blob/master/bootstrap.sh). The installation process is pretty simple on Mac OS X with [Homebrew](http://mxcl.github.io/homebrew/) & [git](http://git-scm.com/).

### Install Fresh:

    bash -c "`curl -sL get.freshshell.com`"

### Clone the repo:
    git clone https://github.com/simshanith/dotfiles.git ~/.dotfiles

### Copy files:
    cp -vf ~/.dotfiles/.{bash_profile,bashrc,freshrc} ~

Footnote: I think Sam Stephenson said it best when discussing his move from zsh to bash in his blog post ["On Configuration"](http://sstephenson.us/posts/on-configuration).

> What I discovered is that in many cases, my ability to adapt to a foreign environment without frustration is more important than the benefits of configuring a local environment to suit my whims. And that being able to quickly recreate my environment from scratch is an asset.