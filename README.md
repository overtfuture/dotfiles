# Dotfiles

## Quick Start

Clone, cd, symlink

```shell
git clone git@github.com:overtfuture/dotfiles.git

cd dotfiles && DOTFILE_DIR=$(pwd) && cd

ln -s $DOTFILE_DIR/.zprofile $HOME/.zprofile
ln -s $DOTFILE_DIR/.zshrc $HOME/.zshrc

# Language specific files / other tools

# ln -s the entire folder
ln -s $DOTFILE_DIR/.zsh-tooling $HOME/.zsh-tooling

# ln -s individual files
# ln -s $DOTFILE_DIR/.zsh-tooling/node $HOME/.zsh-tooling/node
# ...others

# More specific configs
ln -s $DOTFILE_DIR/.zshrc_private $HOME/.zshrc_private
ln -s $DOTFILE_DIR/.config/starship $HOME/.config/starship
```

But it's not DRY... that's okay, it's explicit 🍻