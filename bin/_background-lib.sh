#!/usr/bin/env bash
#
# Shared helpers for the wallpaper commands: where wallpapers come from, and
# which one is current.
#
# Not a command — the leading underscore keeps it out of the dispatcher's scan.
# Source it after _lib.sh and _theme-lib.sh (it uses settings_theme/theme_path),
# with MONARCH_HOME already resolved.

# The one image the user last set, so `next` knows where it is in the cycle.
MONARCH_BG_STATE="$MONARCH_STATE_DIR/background"

# Every wallpaper available to the active theme, deduplicated by the caller's
# use, one path per line. Two sources, in this order:
#
#   <active theme>/backgrounds/       per-theme — the shipped ones, and any you
#                                     drop beside them. Changes with the theme.
#   ~/.config/monarch/backgrounds/    yours — follows you across every theme.
#
# The order matters: `theme apply` sets the first line, and a theme should lead
# with its own art rather than with whatever the user dropped in the shared
# directory.
background_candidates() {
  local dirs=() name dir

  if name=$(settings_theme 2>/dev/null) && dir=$(theme_path "$name" 2>/dev/null); then
    dirs+=("$dir/backgrounds")
  fi
  dirs+=("$MONARCH_CONFIG_DIR/monarch/backgrounds")

  local d
  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] || continue
    find "$d" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
      | sort
  done
}

# Where a person is told to put their own images, when there are none.
background_help_where() {
  printf 'Drop images into either of these:\n' >&2
  printf '  <active theme>/backgrounds/\n' >&2
  printf '  %s/monarch/backgrounds/   (kept across themes)\n' \
    "${MONARCH_CONFIG_DIR/#$HOME/\~}" >&2
  printf '\nMonARCH ships a few per theme; every added image needs a recorded\n' >&2
  printf 'licence if it is ever committed. jpg, jpeg, png and webp.\n' >&2
}
