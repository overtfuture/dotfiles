#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

bash_files=(install.sh .bin/setup-gitconfig .bin/update-system .bin/lib/github-keys.sh
  .bin/macos/setup-dependencies .bin/debian/setup-dependencies tests/*.sh)
for file in "${bash_files[@]}"; do
  bash -n "$file"
done
for file in .zshrc .zprofile .zshrc_private .zsh-tooling/* .bin/lib/*.zsh tests/*.zsh; do
  zsh -n "$file"
done
shellcheck -x "${bash_files[@]}"
bash tests/install.sh
zsh tests/git-signing.zsh
zsh tests/tooling.zsh
bash tests/update.sh
