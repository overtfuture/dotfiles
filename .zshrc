export ZSH="$HOME/.oh-my-zsh"

# Default Theme
ZSH_THEME="imajes"

# Plugins
plugins=(
  1password
  brew
  colorize
  docker
  fnm
  fzf
  git
  golang
  kubectl
  vi-mode
  zsh-autosuggestions
  zsh-interactive-cd
  zsh-navigation-tools
)

# Source oh my zsh
source $ZSH/oh-my-zsh.sh

ZSH_DISABLE_COMPFIX=true

# zsh colorize
ZSH_COLORIZE_TOOL=chroma
ZSH_COLORIZE_STYLE="colorful"
ZSH_COLORIZE_CHROMA_FORMATTER=true-color

# zsh-completions
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

# ZSH Highlighting
if [[ `uname` == "Linux" ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ `uname` == "Darwin" ]]; then
  source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
  echo 'Unknown OS!'
fi

# Basic Aliases
alias c="clear"

# Tooling Configurations
TOOLING_DIR="$HOME/.zsh-tooling"
if [[ -d "$TOOLING_DIR" ]]; then
  for tool in $TOOLING_DIR/*; do
    source $tool
  done
fi

# bat, cat with wings
if [ -x "$(command -v bat)" ]; then
  alias cat='bat --paging=always'
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# eza, better ls
if [ -x "$(command -v eza)" ]; then
  alias ls='eza --color=always --long --git --icons=always'
fi

# fzf, fuzzy finder
if [ -x "$(command -v fzf)" ]; then 
  source <(fzf --zsh)

  # Set fzf theme to dracula and show file previews
  export FZF_DEFAULT_OPTS='
    --height 100% --layout=reverse
    --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
    --color=fg+:#50fa7b,bg+:#44475a,hl+:#ff79c6
    --color=info:#8be9fd,prompt:#ffb86c,pointer:#ff5555
    --color=marker:#ff79c6,spinner:#6272a4,header:#bd93f9
    --preview "[ -f $(echo {} | awk '\''{print $NF}'\'') ] && bat --color=always --style=numbers $(echo {} | awk '\''{print $NF}'\'') || echo {}"
    --preview-window=up:2:wrap
  '
  export FZF_CTRL_T_COMMAND='find $HOME/Developer -type f'
  export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers --line-range=:500 {}" --preview-window=top:60%'
fi

# QR Code Generator
if [ -x "$(command -v qrencode)" ]; then 
  alias qr='qrencode -m 2 -t utf8 <<< "$1"'
fi

# Update Aliases for Linux and macOS
if [[ `uname` == "Linux" ]]; then
  if [ -x "$(command -v brew)" ]; then 
    alias update="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && brew update && brew upgrade && brew autoremove && brew doctor"
  else
    alias update="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"
  fi
elif [[ `uname` == "Darwin" ]]; then
  alias update="brew update && brew upgrade && brew autoremove && brew doctor"
else
  echo 'Unknown OS!'
fi

# Source private customization
if [ -f ~/.zshrc_private ]; then
  source ~/.zshrc_private
fi
