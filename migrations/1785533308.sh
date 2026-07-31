#!/usr/bin/env bash
#DESC: T6 — create the mode overlay files
#
# Golden rule 5: every behaviour change ships a migration.
#
# T6 added two `source` lines to hyprland.conf — mode.conf and
# mode-session.conf — and moved position, height, modules-left and
# modules-center out of Waybar's config.jsonc into a mode fragment.
#
# On a machine that installed a pre-T6 checkout, hyprland.conf arrives from the
# update sourcing two files that do not exist, and Waybar arrives with no
# position and no left or centre group. Neither is a config that works.
#
# `monarch mode set <saved>` creates all three. FATAL on failure, unlike most
# migrations: a Hyprland that cannot parse its config does not start a session,
# and an update that leaves you at a blank screen is the worst outcome this
# project has.

set -euo pipefail

: "${MONARCH_HOME:?migrations run through monarch-migrate; set MONARCH_HOME to run one standalone}"

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
settings="$config_dir/monarch/settings.toml"
apply="$MONARCH_HOME/bin/monarch-mode-set"

[[ -x "$apply" ]] || { printf 'monarch-mode-set is missing — cannot create the mode overlays\n' >&2; exit 1; }

mode="tiling"
if [[ -f "$settings" ]]; then
  found=$(sed -n 's/^[[:space:]]*mode[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$settings" | head -n1)
  [[ -n "$found" ]] && mode=$found
fi

# A mode that is no longer installed would abort the whole update. Tiling always
# exists and always works.
if [[ ! -f "$MONARCH_HOME/modes/$mode/meta.toml" \
   && ! -f "$config_dir/monarch/modes/$mode/meta.toml" ]]; then
  printf "mode '%s' is not installed — falling back to tiling\n" "$mode"
  mode="tiling"
fi

printf 'Creating the mode overlay files for %s mode\n' "$mode"

# --no-plugins: an update is not the moment to start compiling hyprbars against
# a Hyprland that may itself have just been updated. Windows mode picks its
# plugin up the next time it is set, which is where the fallback lives.
"$apply" "$mode" --no-reload --no-plugins
