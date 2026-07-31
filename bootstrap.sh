#!/usr/bin/env bash
#DESC: Install MonARCH onto a fresh Arch system
#
# MonARCH bootstrap — the one command that turns a minimal Arch install into a
# MonARCH desktop.
#
#   curl -fsSL https://raw.githubusercontent.com/Johnnycarriere215/MonARCH-Modern-Arch-OS/main/bootstrap.sh | bash
#
# Assumes: minimal Arch, a user account with sudo, Btrfs root, UEFI, network up.
# Running this twice in a row is expected to be harmless. Every stage under
# install/ is written to be re-runnable.

set -euo pipefail

# ---------------------------------------------------------------- settings --

MONARCH_REPO="${MONARCH_REPO:-https://github.com/Johnnycarriere215/MonARCH-Modern-Arch-OS.git}"
MONARCH_REF="${MONARCH_REF:-main}"
MONARCH_HOME="${MONARCH_HOME:-$HOME/.local/share/monarch}"
MONARCH_LOG="${MONARCH_LOG:-/var/log/monarch-install.log}"

CURRENT_STAGE="startup"

# ----------------------------------------------------------------- output ---

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

usage() {
  cat <<'EOF'
MonARCH bootstrap — install MonARCH onto a fresh Arch system.

Usage:
  bootstrap.sh [--help]
  curl -fsSL <raw url>/bootstrap.sh | bash

Requirements, all checked before anything is written:
  - Arch Linux, x86_64
  - Btrfs root filesystem
  - UEFI boot
  - a normal user account with sudo access (do not run this as root)

Environment overrides:
  MONARCH_REPO   git remote to clone            (default: the MonARCH repo)
  MONARCH_REF    branch or tag to check out     (default: main)
  MONARCH_HOME   where MonARCH is installed     (default: ~/.local/share/monarch)
  MONARCH_LOG    install log path               (default: /var/log/monarch-install.log)

Everything printed here is also appended to the log. Re-running is safe.
EOF
}

# ------------------------------------------------------------------ guards ---

# Each guard names exactly what failed. A guard that says "unsupported system"
# and nothing else is a guard that wastes an hour of someone's evening.
check_not_root() {
  if [[ $EUID -eq 0 ]]; then
    err "bootstrap.sh must run as your normal user account, not as root."
    err "MonARCH installs into your home directory and needs to know whose it is."
    err "It will call sudo itself where root is actually required."
    exit 1
  fi
}

check_sudo() {
  command -v sudo >/dev/null 2>&1 \
    || die "sudo is not installed. Install it and add your user to a sudo-capable group."
  info "Requesting sudo access up front so the install does not stall later."
  sudo -v \
    || die "Could not obtain sudo access for user '$USER'."
}

check_arch() {
  local id="" id_like=""
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    id=$(. /etc/os-release && printf '%s' "${ID:-}")
    id_like=$(. /etc/os-release && printf '%s' "${ID_LIKE:-}")
  fi
  if [[ "$id" != "arch" && "$id_like" != *arch* ]]; then
    die "This is not Arch Linux (/etc/os-release ID='${id:-unknown}'). MonARCH is built directly on Arch."
  fi
  command -v pacman >/dev/null 2>&1 \
    || die "pacman not found. This does not look like a working Arch install."
}

check_arch_x86_64() {
  local m; m=$(uname -m)
  [[ "$m" == "x86_64" ]] \
    || die "Unsupported CPU architecture '$m'. MonARCH is x86_64 only."
}

check_btrfs_root() {
  local fs; fs=$(findmnt -no FSTYPE / 2>/dev/null || printf 'unknown')
  [[ "$fs" == "btrfs" ]] \
    || die "Root filesystem is '$fs', not btrfs. MonARCH requires Btrfs for bootable Snapper snapshots."
}

check_uefi() {
  [[ -d /sys/firmware/efi ]] \
    || die "System is booted in BIOS/legacy mode. MonARCH requires UEFI (Limine + Secure Boot off)."
}

check_network() {
  # A soft check. A mirror can be down without the network being down, so this
  # warns rather than dies -- pacman will produce the authoritative error.
  if ! curl -fsS --max-time 8 -o /dev/null https://archlinux.org 2>/dev/null; then
    warn "Could not reach archlinux.org. If package downloads fail, that is why."
  fi
}

run_guards() {
  CURRENT_STAGE="guards"
  info "Checking this system can run MonARCH"
  check_not_root
  check_arch
  check_arch_x86_64
  check_btrfs_root
  check_uefi
  check_sudo
  check_network
  ok "Arch x86_64, Btrfs root, UEFI, sudo available"
}

# ----------------------------------------------------------------- logging ---

setup_logging() {
  CURRENT_STAGE="logging"
  if [[ ! -e "$MONARCH_LOG" ]]; then
    sudo install -m 0644 -o "$USER" -g "$(id -gn)" /dev/null "$MONARCH_LOG" \
      || die "Could not create the install log at $MONARCH_LOG"
  elif [[ ! -w "$MONARCH_LOG" ]]; then
    sudo chown "$USER:$(id -gn)" "$MONARCH_LOG" \
      || die "Install log $MONARCH_LOG exists but is not writable by $USER"
  fi

  {
    printf '\n'
    printf '========================================================\n'
    printf 'MonARCH install — %s\n' "$(date -Is)"
    printf 'user=%s host=%s kernel=%s\n' "$USER" "$(uname -n)" "$(uname -r)"
    printf 'repo=%s ref=%s home=%s\n' "$MONARCH_REPO" "$MONARCH_REF" "$MONARCH_HOME"
    printf '========================================================\n'
  } >>"$MONARCH_LOG"

  # Append, never truncate: a second run keeps the first run's history, which is
  # the whole point of having a log when something breaks on re-install.
  exec > >(tee -a "$MONARCH_LOG") 2>&1
}

# ------------------------------------------------------------------- source ---

# Where is the tree we are going to run? Two cases:
#   piped from curl  -> clone/update MONARCH_HOME and run that
#   run from a clone -> use that clone, so local edits are what gets tested
locate_source() {
  CURRENT_STAGE="source"
  local self_dir=""
  if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    self_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  fi

  if [[ -n "$self_dir" && -f "$self_dir/install/10-preflight.sh" ]]; then
    MONARCH_HOME="$self_dir"
    info "Running from an existing checkout: $MONARCH_HOME"
    ok "Skipping clone — local changes are what will be installed"
    return 0
  fi

  fetch_repo
}

fetch_repo() {
  command -v git >/dev/null 2>&1 || {
    info "Installing git so the MonARCH repo can be fetched"
    sudo pacman -S --needed --noconfirm git
  }

  if [[ -d "$MONARCH_HOME/.git" ]]; then
    info "Updating existing MonARCH checkout at $MONARCH_HOME"
    git -C "$MONARCH_HOME" remote set-url origin "$MONARCH_REPO"
    git -C "$MONARCH_HOME" fetch --depth 1 origin "$MONARCH_REF"
    git -C "$MONARCH_HOME" reset --hard FETCH_HEAD
    git -C "$MONARCH_HOME" clean -fd
  else
    if [[ -e "$MONARCH_HOME" ]]; then
      # Something is there but it is not a git checkout. Move it aside rather
      # than deleting anything we did not create.
      local aside="$MONARCH_HOME.pre-monarch.$(date +%s)"
      warn "$MONARCH_HOME exists and is not a git checkout — moving it to $aside"
      mv "$MONARCH_HOME" "$aside"
    fi
    info "Cloning MonARCH into $MONARCH_HOME"
    mkdir -p "$(dirname "$MONARCH_HOME")"
    git clone --depth 1 --branch "$MONARCH_REF" "$MONARCH_REPO" "$MONARCH_HOME"
  fi
  ok "Source tree ready at $MONARCH_HOME ($(git -C "$MONARCH_HOME" rev-parse --short HEAD))"
}

# ------------------------------------------------------------------- stages ---

run_stages() {
  local stages=()
  while IFS= read -r f; do stages+=("$f"); done < <(
    find "$MONARCH_HOME/install" -maxdepth 1 -name '[0-9]*.sh' -type f | sort -V
  )

  [[ ${#stages[@]} -gt 0 ]] \
    || die "No install stages found in $MONARCH_HOME/install"

  local stage
  for stage in "${stages[@]}"; do
    CURRENT_STAGE=$(basename "$stage")
    printf '\n'
    info "Stage: $CURRENT_STAGE"
    # Sourced, not executed: stages share MONARCH_HOME, the log, and the helper
    # functions above, and a failure inside one aborts the whole install.
    # shellcheck disable=SC1090
    source "$stage"
  done
  CURRENT_STAGE="complete"
}

# --------------------------------------------------------------- exit paths ---

on_exit() {
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    printf '\n'
    err "MonARCH install failed during stage: $CURRENT_STAGE (exit $rc)"
    # Guards run before logging is set up, so only point at a log that is real.
    if [[ -f "$MONARCH_LOG" ]]; then
      err "Full log: $MONARCH_LOG"
    fi
    err "Nothing has been rolled back. Fix the cause and run bootstrap.sh again —"
    err "it is safe to re-run and will skip what already succeeded."
  fi
  return $rc
}

main() {
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    "") ;;
    *) err "Unknown argument: $1"; printf '\n'; usage; exit 1 ;;
  esac

  trap on_exit EXIT

  printf '%s\n' "$C_BOLD"
  printf '  MonARCH — installing onto Arch Linux\n'
  printf '%s\n' "$C_RESET"

  run_guards
  setup_logging
  locate_source

  export MONARCH_HOME MONARCH_LOG MONARCH_REPO MONARCH_REF

  run_stages

  printf '\n'
  ok "MonARCH install finished. Log: $MONARCH_LOG"
}

main "$@"
