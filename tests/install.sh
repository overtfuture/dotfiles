#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=install.sh
source "$REPO_DIR/install.sh"
[[ "$DOTFILE_DIR" == "$REPO_DIR" ]] || { echo 'FAIL: sourced installer resolved the wrong repository' >&2; exit 1; }
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

mkdir -p "$DOTFILE_DIR/.codex"
printf '[history]\npersistence = "save-all"\n' > "$DOTFILE_DIR/.codex/config.example.toml"
printf 'shared instructions\n' > "$DOTFILE_DIR/.codex/AGENTS.md"
setup_codex >/dev/null
[[ -f "$HOME/.codex/config.toml" && ! -L "$HOME/.codex/config.toml" ]] || fail 'fresh Codex config must be a local file'
cmp "$DOTFILE_DIR/.codex/config.example.toml" "$HOME/.codex/config.toml" || fail 'fresh Codex defaults differ'
printf 'machine-specific settings\n' > "$HOME/.codex/config.toml"
setup_codex >/dev/null
[[ "$(cat "$HOME/.codex/config.toml")" == 'machine-specific settings' ]] || fail 'existing Codex settings overwritten'

rm "$HOME/.codex/config.toml"
printf 'legacy machine settings\n' > "$DOTFILE_DIR/.codex/config.toml"
ln -s "$DOTFILE_DIR/.codex/config.toml" "$HOME/.codex/config.toml"
setup_codex >/dev/null
[[ ! -L "$HOME/.codex/config.toml" ]] || fail 'legacy Codex symlink was not detached'
[[ "$(cat "$HOME/.codex/config.toml")" == 'legacy machine settings' ]] || fail 'legacy symlink contents lost'
[[ "$(cat "$DOTFILE_DIR/.codex/config.toml")" == 'legacy machine settings' ]] || fail 'legacy source changed'
backups=("$HOME"/.codex/config.toml.bak.*)
[[ -L "${backups[0]}" ]] || fail 'legacy symlink was not backed up'

rm "$HOME/.codex/config.toml"
ln -s "$HOME/missing-config" "$HOME/.codex/config.toml"
setup_codex >/dev/null
[[ -f "$HOME/.codex/config.toml" && ! -L "$HOME/.codex/config.toml" ]] || fail 'broken Codex symlink was not repaired'
cmp "$DOTFILE_DIR/.codex/config.example.toml" "$HOME/.codex/config.toml" || fail 'broken symlink defaults differ'
echo 'Installer tests passed'
