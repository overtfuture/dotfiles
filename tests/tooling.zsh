#!/usr/bin/env zsh
set -eu
REPO_DIR=${0:A:h:h}
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/home/.zsh-tooling/directory"
print '(( DOTFILES_TEST_MODULE_COUNT += 1 ))' > "$TEST_DIR/module"
cp "$TEST_DIR/module" "$TEST_DIR/home/.zsh-tooling/regular"
ln -s "$TEST_DIR/module" "$TEST_DIR/home/.zsh-tooling/linked"
ln -s "$TEST_DIR/missing" "$TEST_DIR/home/.zsh-tooling/broken"

# Load the actual startup file in a temporary home without user integrations.
if ! env HOME="$TEST_DIR/home" PATH=/usr/bin:/bin zsh -f -c '
  DOTFILES_TEST_MODULE_COUNT=0
  source "$1"
  [[ $DOTFILES_TEST_MODULE_COUNT == 2 ]]
' -- "$REPO_DIR/.zshrc" >"$TEST_DIR/output" 2>&1; then
  print -u2 'FAIL: regular and symlinked tooling modules must both load'
  cat "$TEST_DIR/output" >&2
  exit 1
fi
print 'Tooling startup tests passed'
