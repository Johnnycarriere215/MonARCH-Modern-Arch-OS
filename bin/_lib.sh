#!/usr/bin/env bash
#
# Shared helpers for the monarch CLI.
#
# Deliberately named without the 'monarch-' prefix so the dispatcher's scan
# does not offer it as a command and 30-config.sh does not symlink it.
#
# Sourcing it needs MONARCH_HOME already resolved, which is a chicken-and-egg
# problem for a symlinked script — so each command carries the six-line
# resolve preamble and sources this for everything else.

# ------------------------------------------------------------------ output ---

if [[ -t 1 ]]; then
  C_RESET=$'\e[0m'; C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'
  C_RED=$'\e[31m'; C_GREEN=$'\e[32m'; C_YELLOW=$'\e[33m'; C_BLUE=$'\e[34m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""
fi

info()  { printf '%s::%s %s\n' "$C_BLUE$C_BOLD" "$C_RESET" "$*"; }
step()  { printf '%s  ->%s %s\n' "$C_DIM" "$C_RESET" "$*"; }
ok()    { printf '%s  ok%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf '%swarn:%s %s\n' "$C_YELLOW$C_BOLD" "$C_RESET" "$*" >&2; }
err()   { printf '%serror:%s %s\n' "$C_RED$C_BOLD" "$C_RESET" "$*" >&2; }
die()   { err "$*"; exit 1; }

# A change the user needs to actually notice, as opposed to progress chatter.
loud() {
  printf '%s  !!%s %s%s%s\n' "$C_YELLOW$C_BOLD" "$C_RESET" "$C_BOLD" "$*" "$C_RESET"
}

have() { command -v "$1" >/dev/null 2>&1; }

# -------------------------------------------------------------------- paths ---

MONARCH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
MONARCH_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/monarch"

# What monarch-config-apply last wrote, so a later run can tell "the user
# edited this" apart from "we shipped a new version of this".
MONARCH_MANIFEST="$MONARCH_STATE_DIR/config-manifest"

# ----------------------------------------------------------------- hashing ---

hash_file() {
  [[ -f "$1" ]] || return 1
  sha256sum "$1" | cut -d' ' -f1
}

manifest_get() {
  local rel=$1
  [[ -f "$MONARCH_MANIFEST" ]] || return 1
  # Format: <sha256><TAB><relative path>
  awk -F'\t' -v k="$rel" '$2 == k { print $1; found=1 } END { exit !found }' \
    "$MONARCH_MANIFEST"
}

manifest_set() {
  local rel=$1 sum=$2
  mkdir -p "$MONARCH_STATE_DIR"
  touch "$MONARCH_MANIFEST"
  local tmp; tmp=$(mktemp)
  awk -F'\t' -v k="$rel" '$2 != k' "$MONARCH_MANIFEST" >"$tmp"
  printf '%s\t%s\n' "$sum" "$rel" >>"$tmp"
  sort -k2 -t$'\t' "$tmp" -o "$tmp"
  mv "$tmp" "$MONARCH_MANIFEST"
}

# --------------------------------------------------------------- seed-only ---

# Files listed in config/.seed-only are written once and then left alone.
# Loaded once into an array rather than re-read per file.
SEED_ONLY_PATTERNS=()

load_seed_only() {
  local file="$MONARCH_HOME/config/.seed-only"
  SEED_ONLY_PATTERNS=()
  [[ -f "$file" ]] || return 0
  local line
  while IFS= read -r line; do
    line=${line%%#*}
    line=${line//[[:space:]]/}
    [[ -n "$line" ]] && SEED_ONLY_PATTERNS+=("$line")
  done <"$file"
}

is_seed_only() {
  local rel=$1 pattern
  for pattern in "${SEED_ONLY_PATTERNS[@]}"; do
    # shellcheck disable=SC2053  # glob match is the point
    [[ "$rel" == $pattern ]] && return 0
  done
  return 1
}
