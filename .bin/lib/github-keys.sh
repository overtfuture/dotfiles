#!/usr/bin/env bash

# Shared helpers for safely downloading public SSH keys from GitHub.

validate_github_username() {
  local username="$1"

  [[ "$username" =~ ^[A-Za-z0-9][A-Za-z0-9-]{0,38}$ ]] &&
    [[ "$username" != *--* ]] &&
    [[ "$username" != *- ]]
}

fetch_github_keys() {
  local username="$1"
  local destination="$2"
  local principal="${3:-}"
  local raw_file
  local output_file

  if ! validate_github_username "$username"; then
    echo "Invalid GitHub username: $username" >&2
    return 2
  fi

  if [[ -n "$principal" && ( "$principal" =~ [[:space:]] || "$principal" == *","* ) ]]; then
    echo "Invalid allowed-signers principal: $principal" >&2
    return 2
  fi

  command -v curl >/dev/null 2>&1 || {
    echo "Missing dependency: curl" >&2
    return 1
  }

  mkdir -p "$(dirname "$destination")"
  chmod 700 "$(dirname "$destination")"

  raw_file="$(mktemp "${destination}.raw.XXXXXX")"
  output_file="$(mktemp "${destination}.new.XXXXXX")"

  if ! curl --proto '=https' --tlsv1.2 --fail --silent --show-error \
    --location --max-time 30 "https://github.com/${username}.keys" >"$raw_file"; then
    rm -f "$raw_file" "$output_file"
    return 1
  fi

  if [[ ! -s "$raw_file" ]] || ! awk '
    NF >= 2 && $1 ~ /^(ssh-(ed25519|rsa)|ecdsa-sha2-nistp(256|384|521)|sk-(ssh-ed25519|ecdsa-sha2-nistp256)@openssh.com)$/ { next }
    { exit 1 }
  ' "$raw_file"; then
    echo "GitHub returned no valid public SSH keys for $username" >&2
    rm -f "$raw_file" "$output_file"
    return 1
  fi

  if [[ -n "$principal" ]]; then
    awk -v principal="$principal" '{ print principal, $0 }' "$raw_file" >"$output_file"
  else
    cp "$raw_file" "$output_file"
  fi

  chmod 600 "$output_file"
  mv -f "$output_file" "$destination"
  rm -f "$raw_file"
}
