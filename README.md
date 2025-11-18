# Dotfiles

## Quick Start

Clone, cd, symlink

```shell
git clone https://github.com/overtfuture/dotfiles.git

cd dotfiles && DOTFILE_DIR=$(pwd) && cd

ln -s $DOTFILE_DIR/.zprofile $HOME/.zprofile
ln -s $DOTFILE_DIR/.zshrc $HOME/.zshrc
ln -s $DOTFILE_DIR/.gitignore_global $HOME/.gitignore_global

# Language specific files / other tools

# ln -s the entire folder
ln -s $DOTFILE_DIR/.zsh-tooling $HOME/.zsh-tooling

# ln -s individual files
# ln -s $DOTFILE_DIR/.zsh-tooling/node $HOME/.zsh-tooling/node
# ...others

# More specific configs
ln -s $DOTFILE_DIR/.zshrc_private $HOME/.zshrc_private
mkdir -p $HOME/.config && ln -s $DOTFILE_DIR/.config/starship $HOME/.config/starship

# Clone and setup Neovim config
if ! [[ -d $HOME/.config/nvim ]]; then git clone https://github.com/overtfuture/lazyvim.git $HOME/.config/nvim; fi

# Custom binaries
if ! [[ -d $HOME/.bin ]]; then ln -s $DOTFILE_DIR/.bin $HOME/.bin; fi

# OpenSSH Config
sudo mv $DOTFILE_DIR/001-ssh-macos-security.conf /etc/ssh/sshd_config.d/
sudo mv $DOTFILE_DIR/100-macos.conf /etc/ssh/sshd_config.d/

# Reload config
exec zsh

# Setup dependencies (macOS only)
setup-dependencies

# Setup ~/.gitconfig
setup-gitconfig
```

But it's not DRY... that's okay, it's explicit 🍻
