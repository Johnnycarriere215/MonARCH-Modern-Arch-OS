#!/usr/bin/env bash
#DESC: Shared helpers for install stages (not a stage itself)
#
# Sourced by every install/NN-*.sh stage. Deliberately not named with a leading
# digit so bootstrap.sh's stage glob skips it.
#
# Everything here is idempotent by construction: writes compare before they
# replace, and nothing is deleted that MonARCH did not create.

# Stages can be sourced standalone for debugging (MONARCH_HOME=... source
# install/20-packages.sh). When that happens bootstrap's output helpers are
# missing, so define plain fallbacks.
if ! declare -F info >/dev/null 2>&1; then
  info()  { printf ':: %s\n' "$*"; }
  step()  { printf '  -> %s\n' "$*"; }
  ok()    { printf '  ok %s\n' "$*"; }
  warn()  { printf 'warn: %s\n' "$*" >&2; }
  err()   { printf 'error: %s\n' "$*" >&2; }
  die()   { err "$*"; exit 1; }
fi

[[ -n "${MONARCH_HOME:-}" ]] \
  || die "MONARCH_HOME is unset. Install stages run through bootstrap.sh."

# --------------------------------------------------------------- packages ---

# Read a package manifest into stdout, one name per line.
# Strips '#' comments (whole-line and trailing) and blank lines, so manifests
# stay readable without the stages needing to care.
parse_packages() {
  local file=$1
  [[ -r "$file" ]] || die "Package manifest not found: $file"
  sed -e 's/#.*//' -e 's/[[:space:]]\+$//' -e 's/^[[:space:]]\+//' "$file" \
    | grep -v '^$' || true
}

# --------------------------------------------------------------- file I/O ---

# Write stdin to a root-owned path, but only if the content actually differs.
# Keeps the log honest about what changed on a re-run.
write_system_file() {
  local dest=$1 mode=${2:-0644}
  local tmp; tmp=$(mktemp)
  cat >"$tmp"

  if [[ -f "$dest" ]] && sudo cmp -s "$tmp" "$dest"; then
    step "$dest already correct"
    rm -f "$tmp"
    return 0
  fi

  if [[ -f "$dest" ]]; then
    local backup="$dest.monarch-$(date +%Y%m%d%H%M%S).bak"
    step "backing up existing $dest -> $backup"
    sudo cp -a "$dest" "$backup"
  fi

  sudo install -D -m "$mode" "$tmp" "$dest"
  rm -f "$tmp"
  ok "wrote $dest"
}

# Deploying into $HOME lives in bin/monarch-config-apply, not here. The
# installer shells out to it (golden rule 1), so there is one implementation of
# "do not clobber the user's edits" rather than two that drift apart.

# ------------------------------------------------------------------ units ---

# Enable a systemd unit only if it exists, and never --now for units that would
# take over the current session (greetd). Missing units warn instead of dying:
# a bluetooth-less VM should not fail an install.
enable_unit() {
  local unit=$1 now=${2:-no}

  if ! systemctl list-unit-files "$unit" >/dev/null 2>&1 \
     || [[ -z $(systemctl list-unit-files --no-legend "$unit" 2>/dev/null) ]]; then
    warn "unit $unit not found — skipping (is its package installed?)"
    return 0
  fi

  if [[ "$now" == "now" ]]; then
    sudo systemctl enable --now "$unit"
  else
    sudo systemctl enable "$unit"
  fi
  step "enabled $unit"
}

# ---------------------------------------------------------------- helpers ---

have() { command -v "$1" >/dev/null 2>&1; }

# Keep the sudo timestamp alive across long pacman runs.
sudo_refresh() { sudo -v || die "Lost sudo access mid-install."; }

# Add a line to a file exactly once, identified by a marker comment.
ensure_line_in_file() {
  local file=$1 marker=$2 line=$3
  touch "$file"
  if grep -qF "$marker" "$file"; then
    return 0
  fi
  printf '\n%s\n%s\n' "$marker" "$line" >>"$file"
  step "appended to $file: $line"
}
