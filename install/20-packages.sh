#!/usr/bin/env bash
#DESC: Stage 20 — install base packages, bootstrap paru, install AUR packages
#
# Sourced by bootstrap.sh. Safe to re-run: pacman --needed and paru --needed
# both no-op on an already-installed package.

: "${MONARCH_HOME:?install stages run through bootstrap.sh; set MONARCH_HOME to run one standalone}"

# shellcheck source=/dev/null
source "$MONARCH_HOME/install/_common.sh"

stage_20_base() {
  local manifest="$MONARCH_HOME/packages/base.packages"
  local pkgs=()
  while IFS= read -r p; do pkgs+=("$p"); done < <(parse_packages "$manifest")

  [[ ${#pkgs[@]} -gt 0 ]] || die "No packages parsed from $manifest"

  info "Installing ${#pkgs[@]} base packages"
  sudo_refresh
  sudo pacman -S --needed --noconfirm "${pkgs[@]}" \
    || die "Base package install failed. See the pacman output above."
  ok "base packages installed"
}

stage_20_paru() {
  if have paru; then
    ok "paru already present"
    return 0
  fi

  info "Bootstrapping paru (AUR helper)"
  local build; build=$(mktemp -d)
  # paru-bin, not paru: building paru from source pulls in the whole Rust
  # toolchain for no benefit on a fresh install.
  git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$build/paru-bin" \
    || die "Could not clone paru-bin from the AUR."

  (
    cd "$build/paru-bin" || exit 1
    # makepkg refuses to run as root and calls sudo itself for -i.
    makepkg -si --noconfirm
  ) || die "Building paru failed. Check that base-devel installed correctly."

  rm -rf "$build"
  have paru || die "paru still not on PATH after install."
  ok "paru installed"
}

stage_20_aur() {
  local manifest="$MONARCH_HOME/packages/aur.packages"
  local pkgs=()
  while IFS= read -r p; do pkgs+=("$p"); done < <(parse_packages "$manifest")

  if [[ ${#pkgs[@]} -eq 0 ]]; then
    ok "no AUR packages listed"
    return 0
  fi

  info "Installing ${#pkgs[@]} AUR packages"

  # One at a time, on purpose. AUR builds break for reasons outside our control
  # (upstream tarball moved, a dependency bumped) and one bad package should not
  # cost you the whole desktop. Failures are collected and reported at the end.
  local failed=()
  local p
  for p in "${pkgs[@]}"; do
    step "aur: $p"
    sudo_refresh
    if ! paru -S --needed --noconfirm --skipreview "$p"; then
      warn "AUR package '$p' failed to build — continuing"
      failed+=("$p")
    fi
  done

  if [[ ${#failed[@]} -gt 0 ]]; then
    warn "These AUR packages did not install: ${failed[*]}"
    warn "The desktop will still come up. Retry later with: paru -S ${failed[*]}"
  else
    ok "AUR packages installed"
  fi
}

stage_20_packages() {
  stage_20_base
  stage_20_paru
  stage_20_aur
}

stage_20_packages
