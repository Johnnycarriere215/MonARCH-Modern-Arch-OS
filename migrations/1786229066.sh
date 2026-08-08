#!/usr/bin/env bash
#DESC: Wallpapers ship now — regenerate keybinds, set one if none is set
#
# Golden rule 5: every behaviour change ships a migration.
#
# Two things changed that an existing machine will not pick up on its own:
#
#   1. schema/keybinds.toml gained `background-pick` (Super+Ctrl+W). `monarch
#      update` runs `config apply`, not `keys apply`, so the generated
#      bindings.conf would not get it. This regenerates — which for a user with
#      their own keymap uses THEIR file (so it is a no-op for them, correctly).
#
#   2. Each theme now ships wallpapers. The files arrive with the git pull, so
#      `background next`/`pick` find them with no help. But a machine installed
#      before this has no wallpaper set at all, and it is nicer to land on the
#      theme's default than on Hyprland's grey. Only sets one if none is set —
#      never overrides a wallpaper the user chose.
#
# Idempotent.

set -euo pipefail

: "${MONARCH_HOME:?migrations run through monarch-migrate; set MONARCH_HOME to run one standalone}"

# ---- the new keybind ---------------------------------------------------------
keys="$MONARCH_HOME/bin/monarch-keys-apply"
if [[ -x "$keys" ]]; then
  printf 'Regenerating keybinds (adds Super+Ctrl+W — pick a wallpaper)\n'
  MONARCH_HOME="$MONARCH_HOME" "$keys" >/dev/null 2>&1 \
    || printf 'could not regenerate keybinds — run: monarch keys apply\n'
fi

# ---- a default wallpaper, only if none is set --------------------------------
state="${XDG_STATE_HOME:-$HOME/.local/state}/monarch/background"
if [[ -s "$state" ]]; then
  printf 'a wallpaper is already set — leaving it\n'
  exit 0
fi

# theme apply picks the active theme's first wallpaper. --no-reload and
# --no-background would skip exactly the part we want, so call the background
# command directly via `next` from an empty state (lands on the first).
next="$MONARCH_HOME/bin/monarch-background-next"
[[ -x "$next" ]] || exit 0

printf 'Setting the active theme default wallpaper\n'
MONARCH_HOME="$MONARCH_HOME" "$next" >/dev/null 2>&1 \
  || printf 'no wallpaper set — try: monarch background pick\n'
