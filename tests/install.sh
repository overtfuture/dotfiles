#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=install.sh
source "$REPO_DIR/install.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
export HOME="$TEST_DIR/home"
DOTFILE_DIR="$TEST_DIR/repo"
mkdir -p "$HOME" "$DOTFILE_DIR/.zsh-tooling"
printf 'github module\n' > "$DOTFILE_DIR/.zsh-tooling/github"
printf 'node module\n' > "$DOTFILE_DIR/.zsh-tooling/node"

fail() { echo "FAIL: $*" >&2; exit 1; }

symlink "$DOTFILE_DIR/.zsh-tooling/github" "$HOME/example" >/dev/null
symlink "$DOTFILE_DIR/.zsh-tooling/github" "$HOME/example" >/dev/null
[[ -L "$HOME/example" ]] || fail 'fresh link or rerun failed'
[[ -z "$(find "$HOME" -name 'example.bak.*' -print)" ]] || fail 'rerun backed up a correct link'

printf 'original\n' > "$HOME/existing"
symlink "$DOTFILE_DIR/.zsh-tooling/github" "$HOME/existing" >/dev/null
[[ "$(cat "$HOME"/existing.bak.*)" == original ]] || fail 'existing file was not preserved'
ln -s "$HOME/missing" "$HOME/broken"
symlink "$DOTFILE_DIR/.zsh-tooling/github" "$HOME/broken" >/dev/null
[[ -f "$HOME/broken" ]] || fail 'broken link was not replaced'

# Reproduce a legacy all-modules install, then select just one module.
ln -s "$DOTFILE_DIR/.zsh-tooling" "$HOME/.zsh-tooling"
setup_zsh_tooling <<< '1' >/dev/null
[[ ! -L "$HOME/.zsh-tooling" ]] || fail 'tooling destination is still a directory symlink'
[[ -f "$DOTFILE_DIR/.zsh-tooling/github" && ! -L "$DOTFILE_DIR/.zsh-tooling/github" ]] || fail 'installer modified the source module'
[[ -f "$HOME/.zsh-tooling/github" ]] || fail 'selected module does not work'
[[ ! -e "$HOME/.zsh-tooling/node" ]] || fail 'unselected module was installed'
setup_zsh_tooling <<< 'a' >/dev/null
setup_zsh_tooling <<< 'a' >/dev/null
[[ -f "$HOME/.zsh-tooling/node" ]] || fail 'all-modules installation failed'
[[ -z "$(find "$DOTFILE_DIR" -name '*.bak.*' -print)" ]] || fail 'repository contains installer backups'
echo 'Installer tests passed'
