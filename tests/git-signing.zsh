#!/usr/bin/env zsh
set -eu
REPO_DIR=${0:A:h:h}
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
export HOME="$TEST_DIR/home with spaces"
mkdir -p "$HOME/.ssh"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
printf '[user]\n\tname = preserved-name\n' > "$GIT_CONFIG_GLOBAL"
cp "$GIT_CONFIG_GLOBAL" "$TEST_DIR/original"
touch "$GIT_CONFIG_GLOBAL.lock"
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=test.preserved GIT_CONFIG_VALUE_0=yes
unset DOTFILES_GIT_SIGNING_CONFIG_START DOTFILES_GIT_SIGNING_CONFIG_COUNT

fail() { print -u2 "FAIL: $*"; exit 1; }

# Run the real private shell configuration without optional installed tools.
export PATH=/usr/bin:/bin
mkdir -p "$HOME/.bin/lib"
ln -s "$REPO_DIR/.bin/lib/git-signing.zsh" "$HOME/.bin/lib/git-signing.zsh"
OSTYPE=darwin
export SSH_CONNECTION=''
source "$REPO_DIR/.zshrc_private"
[[ "$(git config gpg.ssh.program)" == /Applications/1Password.app/Contents/MacOS/op-ssh-sign ]] || fail 'local macOS signer'
if git config user.signingkey >/dev/null; then
  fail 'signing key was set without a key file'
fi
[[ "$(git config gpg.ssh.defaultKeyCommand)" == 'ssh-add -L' ]] || fail 'agent fallback'
# With no key file or persistent key, signing must actually select the agent.
git init -q "$TEST_DIR/commit"
export DOTFILES_TEST_AGENT_CALLED="$TEST_DIR/agent-called"
cat > "$TEST_DIR/agent-command" <<'SH'
#!/bin/sh
: > "$DOTFILES_TEST_AGENT_CALLED"
exit 1
SH
chmod +x "$TEST_DIR/agent-command"
if git -C "$TEST_DIR/commit" -c user.name=Test -c user.email=test@example.com \
  -c gpg.format=ssh -c "gpg.ssh.defaultKeyCommand=$TEST_DIR/agent-command" \
  commit --allow-empty -S -m test >"$TEST_DIR/commit-output" 2>&1; then
  fail 'signing unexpectedly succeeded without an agent key'
fi
[[ -f "$TEST_DIR/agent-called" ]] || { cat "$TEST_DIR/commit-output"; fail 'agent fallback was not invoked'; }
[[ "$(git config test.preserved)" == yes ]] || fail 'inherited setting lost'
cmp "$GIT_CONFIG_GLOBAL" "$TEST_DIR/original" || fail 'global config changed'
count=$GIT_CONFIG_COUNT
source "$REPO_DIR/.zshrc_private"
[[ $GIT_CONFIG_COUNT == $count ]] || fail 'reloading accumulated overrides'
# Overrides added by another tool must survive reconfiguration.
export "GIT_CONFIG_KEY_$GIT_CONFIG_COUNT=test.appended"
export "GIT_CONFIG_VALUE_$GIT_CONFIG_COUNT=kept"
export GIT_CONFIG_COUNT=$((GIT_CONFIG_COUNT + 1))
source "$REPO_DIR/.zshrc_private"
[[ "$(git config test.appended)" == kept ]] || fail 'appended setting lost'

touch "$HOME/.ssh/1password_signing_key.pub"
source "$REPO_DIR/.zshrc_private"
[[ "$(git config user.signingkey)" == "$HOME/.ssh/1password_signing_key.pub" ]] || fail 'local key with spaces'
export "GIT_CONFIG_KEY_$GIT_CONFIG_COUNT=test.after-key"
export "GIT_CONFIG_VALUE_$GIT_CONFIG_COUNT=preserved"
export GIT_CONFIG_COUNT=$((GIT_CONFIG_COUNT + 1))
rm "$HOME/.ssh/1password_signing_key.pub"
export SSH_CONNECTION='test connection'
source "$REPO_DIR/.zshrc_private"
if git config user.signingkey >/dev/null; then
  fail 'old key survived an appended override and SSH transition'
fi
[[ "$(git config test.after-key)" == preserved ]] || fail 'override after the old key was lost'
export SSH_CONNECTION='test connection'
touch "$HOME/.ssh/git_signing_key.pub"
source "$REPO_DIR/.zshrc_private"
[[ "$(git config gpg.ssh.program)" == ssh-keygen ]] || fail 'SSH signer'
[[ "$(git config user.signingkey)" == "$HOME/.ssh/git_signing_key.pub" ]] || fail 'SSH key'
OSTYPE=linux-gnu
export SSH_CONNECTION=''
source "$REPO_DIR/.zshrc_private"
[[ "$(git config gpg.ssh.program)" == ssh-keygen ]] || fail 'Linux signer'
rm "$HOME/.ssh/git_signing_key.pub"
source "$REPO_DIR/.zshrc_private"
if git config user.signingkey >/dev/null; then
  fail 'key override survived removal of its file'
fi
# Respect a persistent key when no shell-specific key file is available.
printf '[user]\n\tsigningkey = explicit-key\n' > "$GIT_CONFIG_GLOBAL"
source "$REPO_DIR/.zshrc_private"
[[ "$(git config user.signingkey)" == explicit-key ]] || fail 'explicit global key was overridden'
export "GIT_CONFIG_KEY_$GIT_CONFIG_COUNT=gpg.ssh.program"
export "GIT_CONFIG_VALUE_$GIT_CONFIG_COUNT=custom-signer"
export GIT_CONFIG_COUNT=$((GIT_CONFIG_COUNT + 1))
source "$REPO_DIR/.zshrc_private"
[[ "$(git config gpg.ssh.program)" == custom-signer ]] || fail 'external signing override lost priority on reload'
print 'Git signing tests passed'
