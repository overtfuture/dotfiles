# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
# Homebrew zsh site functions
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :