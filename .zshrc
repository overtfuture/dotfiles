export ZSH="$HOME/.oh-my-zsh"
ZSH_DISABLE_COMPFIX=true

# Oh My Zsh does not search Linuxbrew's fzf prefix automatically.
if command -v brew >/dev/null 2>&1; then
  if fzf_base="$(brew --prefix fzf 2>/dev/null)" && [[ -d "$fzf_base" ]]; then
    export FZF_BASE="$fzf_base"
  fi
  unset fzf_base
fi

# Default Theme
ZSH_THEME="imajes"

# Plugins
plugins=(
  colorize
  docker
  fnm
  git
  golang
  kubectl
  vi-mode
  zsh-interactive-cd
  zsh-navigation-tools
)

command -v op >/dev/null 2>&1 && plugins+=(1password)
command -v brew >/dev/null 2>&1 && plugins+=(brew)

# zsh colorize
if command -v chroma >/dev/null 2>&1; then
  ZSH_COLORIZE_TOOL=chroma
elif command -v pygmentize >/dev/null 2>&1; then
  ZSH_COLORIZE_TOOL=pygmentize
fi
ZSH_COLORIZE_STYLE="colorful"
ZSH_COLORIZE_CHROMA_FORMATTER=true-color

# Source oh my zsh
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  print -u2 "Oh My Zsh is not installed at $ZSH"
fi

# zsh autosuggestions
if [[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif command -v brew >/dev/null 2>&1 &&
  [[ -r "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Basic Aliases
alias c="clear"

# Tooling Configurations
TOOLING_DIR="$HOME/.zsh-tooling"
if [[ -d "$TOOLING_DIR" ]]; then
  for tool in "$TOOLING_DIR"/*(.N); do
    source "$tool"
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
  if fzf_init="$(fzf --zsh 2>/dev/null)"; then
    eval "$fzf_init"
  elif [[ -r /usr/share/doc/fzf/examples/completion.zsh && -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    source /usr/share/doc/fzf/examples/completion.zsh
    source /usr/share/doc/fzf/examples/key-bindings.zsh
  elif [[ -n "${FZF_BASE:-}" && -r "$FZF_BASE/shell/completion.zsh" && -r "$FZF_BASE/shell/key-bindings.zsh" ]]; then
    source "$FZF_BASE/shell/completion.zsh"
    source "$FZF_BASE/shell/key-bindings.zsh"
  fi
  unset fzf_init

  # Set fzf theme to dracula and show file previews
  export FZF_DEFAULT_OPTS='
    --height 100% --layout=reverse
    --preview "if [ -f {} ]; then bat --color=always --style=numbers -- {}; else printf '%s\\n' {}; fi"
    --preview-window=up:2:wrap
  '
  export FZF_CTRL_T_COMMAND='find $HOME/Developer -type f'
  export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers --line-range=:500 {}" --preview-window=top:60%'
fi

# QR Code Generator
if [ -x "$(command -v qrencode)" ]; then
  qr() {
    if [[ $# -ne 1 ]]; then
      print -u2 'usage: qr <text>'
      return 2
    fi
    printf '%s' "$1" | qrencode -m 2 -t utf8
  }
fi

# Update Aliases for Linux and macOS
update_system() {
  if [[ "$(uname -s)" == "Linux" ]] && command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get upgrade && sudo apt-get autoremove
  fi
  if command -v brew >/dev/null 2>&1; then
    brew update && brew upgrade && brew autoremove && brew doctor
  fi
}
alias update=update_system

# Source private customization
if [ -f "$HOME/.zshrc_private" ]; then
  source "$HOME/.zshrc_private"
fi

# Source secrets customization
if [ -f "$HOME/.zshrc_secrets" ]; then
  # Secret loaders should not announce variable names during every shell start.
  source "$HOME/.zshrc_secrets" >/dev/null
fi

# Optional user-local tools
[[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"
export PATH="$HOME/.local/bin:$PATH"

# Syntax highlighting must be sourced after all widgets and completions.
if [[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif command -v brew >/dev/null 2>&1 &&
  [[ -r "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
