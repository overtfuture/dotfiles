#!/usr/bin/env bash
set -euo pipefail
umask 077

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
      [[ $# -ge 2 && -n "$2" ]] || { echo "Missing value for $1" >&2; exit 2; }
      item="${2:-}"
      shift 2
      ;;
    --vault|-v)
      [[ $# -ge 2 && -n "$2" ]] || { echo "Missing value for $1" >&2; exit 2; }
      vault="${2:-}"
      shift 2
      ;;
    --out|-o)
      [[ $# -ge 2 && -n "$2" ]] || { echo "Missing value for $1" >&2; exit 2; }
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

out_dir="$(dirname "$out")"
if [[ ! -d "$out_dir" || -d "$out" ]]; then
  echo "Output directory does not exist or output is a directory: $out" >&2
  exit 2
fi

tmp="$(mktemp "$out_dir/.1pass-env.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

op "${op_args[@]}" |
  jq -r '
    def env_key:
      ascii_upcase
      | gsub("[^A-Z0-9_]+"; "_")
      | gsub("^_+|_+$"; "")
      | if test("^[0-9]") then "OP_" + . else . end;

    [.fields[]
    | select(.value != null and (.value | tostring | length > 0))
    | {
        key: ((.label // .id) | tostring | env_key),
        value: (.value | tostring)
      }]
    | if length != (unique_by(.key) | length)
      then error("duplicate environment keys after normalization")
      else .
      end
    | sort_by(.key)[]
    | "\(.key)=\(.value | @sh)"
  ' > "$tmp"

chmod 600 "$tmp"
mv "$tmp" "$out"
trap - EXIT

echo "Wrote $out" >&2
