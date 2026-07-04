#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  export-1pass-env.sh --item ITEM [--vault VAULT] [--out .env]

Exports non-empty fields from a 1Password item into a shell-compatible env file.

Requirements:
  - 1Password CLI: op
  - jq

Examples:
  export-1pass-env.sh --item "My App Secrets" --vault Private --out .env.local
  source .env.local
USAGE
}

item=""
vault=""
out=".env"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --item|-i)
      item="${2:-}"
      shift 2
      ;;
    --vault|-v)
      vault="${2:-}"
      shift 2
      ;;
    --out|-o)
      out="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$item" ]]; then
  echo "Missing required --item." >&2
  usage >&2
  exit 2
fi

command -v op >/dev/null 2>&1 || {
  echo "Missing dependency: op. Install and sign in to the 1Password CLI." >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || {
  echo "Missing dependency: jq." >&2
  exit 1
}

op_args=(item get "$item" --format json)
if [[ -n "$vault" ]]; then
  op_args+=(--vault "$vault")
fi

tmp="$(mktemp "${TMPDIR:-/tmp}/1pass-env.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

op "${op_args[@]}" |
  jq -r '
    def env_key:
      ascii_upcase
      | gsub("[^A-Z0-9_]+"; "_")
      | gsub("^_+|_+$"; "")
      | if test("^[0-9]") then "OP_" + . else . end;

    .fields
    | map(select(.value != null and (.value | tostring | length > 0)))
    | map({
        key: ((.label // .id) | tostring | env_key),
        value: (.value | tostring)
      })
    | unique_by(.key)
    | sort_by(.key)
    | .[]
    | "\(.key)=\(.value | @sh)"
  ' > "$tmp"

mv "$tmp" "$out"
trap - EXIT

echo "Wrote $out" >&2
