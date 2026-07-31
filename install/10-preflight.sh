#!/usr/bin/env bash
#DESC: Stage 10 — re-check guards, tune pacman, refresh keyring, full upgrade
#
# Sourced by bootstrap.sh. Safe to re-run.

: "${MONARCH_HOME:?install stages run through bootstrap.sh; set MONARCH_HOME to run one standalone}"

# shellcheck source=/dev/null
source "$MONARCH_HOME/install/_common.sh"

stage_10_recheck_guards() {
  # bootstrap.sh already checked these, but a stage that can be sourced on its
  # own should not assume that.
  [[ $EUID -ne 0 ]]                            || die "Do not run install stages as root."
  [[ "$(uname -m)" == "x86_64" ]]              || die "MonARCH is x86_64 only."
  [[ "$(findmnt -no FSTYPE /)" == "btrfs" ]]   || die "Root filesystem is not btrfs."
  [[ -d /sys/firmware/efi ]]                   || die "Not booted via UEFI."
  ok "guards re-checked"
}

stage_10_pacman_conf() {
  local conf=/etc/pacman.conf
  [[ -f "$conf" ]] || die "$conf missing — this is not a working Arch install."

  # Only touch the two cosmetic/throughput options. Anything more invasive
  # belongs in the user's hands, not an installer's.
  if ! grep -qE '^\s*Color\s*$' "$conf"; then
    step "enabling pacman Color"
    sudo sed -i 's/^#\s*Color\s*$/Color/' "$conf"
    grep -qE '^\s*Color\s*$' "$conf" \
      || sudo sed -i '/^\[options\]/a Color' "$conf"
  fi

  if ! grep -qE '^\s*ParallelDownloads' "$conf"; then
    step "enabling pacman ParallelDownloads = 5"
    sudo sed -i 's/^#\s*ParallelDownloads.*$/ParallelDownloads = 5/' "$conf"
    grep -qE '^\s*ParallelDownloads' "$conf" \
      || sudo sed -i '/^\[options\]/a ParallelDownloads = 5' "$conf"
  fi

  ok "pacman.conf tuned"
}

stage_10_keyring() {
  # Keyring first and on its own. A stale keyring on an old ISO makes every
  # later package fail signature verification with a confusing error.
  info "Refreshing the Arch keyring"
  sudo_refresh
  sudo pacman -Sy --noconfirm --needed archlinux-keyring \
    || die "Could not update archlinux-keyring. Check the system clock and your mirrors."
  ok "keyring current"
}

stage_10_upgrade() {
  info "Full system upgrade (this is the long one)"
  sudo_refresh
  sudo pacman -Syu --noconfirm \
    || die "System upgrade failed. Resolve the pacman error above and re-run bootstrap.sh."
  ok "system up to date"
}

stage_10_preflight() {
  stage_10_recheck_guards
  stage_10_pacman_conf
  stage_10_keyring
  stage_10_upgrade
}

stage_10_preflight
