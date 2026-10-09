#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/bin"
ln -s /bin/bash "$TEST_DIR/bin/bash"
export UPDATE_TEST_LOG="$TEST_DIR/log"

# Package manager doubles avoid changing the host while testing command order
# and failure propagation through the real update function/script.
cat > "$TEST_DIR/bin/manager" <<'SH'
#!/bin/sh
name=${0##*/}
printf '%s %s\n' "$name" "$*" >> "$UPDATE_TEST_LOG"
if [ "${UPDATE_TEST_FAIL:-}" = "$name $*" ]; then
  exit 42
fi
SH
chmod +x "$TEST_DIR/bin/manager"
ln -s manager "$TEST_DIR/bin/apt-get"
ln -s manager "$TEST_DIR/bin/brew"
cat > "$TEST_DIR/bin/uname" <<'SH'
#!/bin/sh
printf '%s\n' "${UPDATE_TEST_OS:-Linux}"
SH
cat > "$TEST_DIR/bin/sudo" <<'SH'
#!/bin/sh
printf 'sudo %s\n' "$*" >> "$UPDATE_TEST_LOG"
exec "$@"
SH
chmod +x "$TEST_DIR/bin/uname" "$TEST_DIR/bin/sudo"
export PATH="$TEST_DIR/bin:/usr/bin:/bin"

fail() { echo "FAIL: $*" >&2; exit 1; }
run_update() {
  : > "$UPDATE_TEST_LOG"
  "$REPO_DIR/.bin/update-system"
} >"$TEST_DIR/output" 2>&1

export UPDATE_TEST_FAIL='apt-get upgrade'
if run_update; then
  fail 'APT failure was hidden by Homebrew success'
fi
if /usr/bin/grep -q '^apt-get autoremove' "$UPDATE_TEST_LOG"; then
  fail 'APT cleanup ran after failed upgrade'
fi
/usr/bin/grep -q '^brew upgrade$' "$UPDATE_TEST_LOG" || fail 'Homebrew was not attempted after APT failure'

export UPDATE_TEST_FAIL='apt-get update'
if run_update; then
  fail 'APT index update failure was hidden'
fi
if /usr/bin/grep -q '^apt-get upgrade' "$UPDATE_TEST_LOG"; then
  fail 'APT upgrade ran after index update failed'
fi

export UPDATE_TEST_OS=Darwin UPDATE_TEST_FAIL='brew upgrade'
if run_update; then
  fail 'Homebrew upgrade failure was ignored'
fi
if /usr/bin/grep -q '^brew autoremove' "$UPDATE_TEST_LOG"; then
  fail 'Homebrew cleanup ran after failed upgrade'
fi

export UPDATE_TEST_FAIL='brew doctor'
if run_update; then
  fail 'Homebrew health check failure was ignored'
fi

unset UPDATE_TEST_FAIL
run_update
expected=$'brew update\nbrew upgrade\nbrew autoremove\nbrew doctor'
[[ "$(cat "$UPDATE_TEST_LOG")" == "$expected" ]] || fail 'macOS update sequence'

export UPDATE_TEST_OS=Linux
run_update
/usr/bin/grep -q '^apt-get autoremove$' "$UPDATE_TEST_LOG" || fail 'APT cleanup missing after successful upgrade'
/usr/bin/grep -q '^brew doctor$' "$UPDATE_TEST_LOG" || fail 'Homebrew checks missing'
if [[ $EUID -eq 0 ]] && /usr/bin/grep -q '^sudo ' "$UPDATE_TEST_LOG"; then
  fail 'root unnecessarily used sudo'
fi

# APT must fail explicitly without sudo for non-root users, while root can
# update directly. Homebrew should still be attempted in either case.
rm "$TEST_DIR/bin/sudo"
if [[ $EUID -eq 0 ]]; then
  PATH="$TEST_DIR/bin" run_update
else
  if PATH="$TEST_DIR/bin" run_update; then
    fail 'non-root APT update succeeded without sudo'
  fi
  if /usr/bin/grep -q '^apt-get ' "$UPDATE_TEST_LOG"; then
    fail 'non-root APT update ran without sudo'
  fi
fi
/usr/bin/grep -q '^brew doctor$' "$UPDATE_TEST_LOG" || fail 'Homebrew was skipped when sudo was missing'

rm "$TEST_DIR/bin/brew"
export UPDATE_TEST_OS=Darwin
if run_update; then
  fail 'missing package manager reported success'
fi
echo 'Update tests passed'
