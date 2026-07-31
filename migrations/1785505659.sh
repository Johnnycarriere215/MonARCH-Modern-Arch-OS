#!/usr/bin/env bash
#DESC: T3 — replace the hand-written palette files with generated ones
#
# Golden rule 5: every behaviour change ships a migration.
#
# Before T3, ~/.config/monarch/theme/{hypr-colors.conf,waybar-colors.css,
# alacritty-colors.toml} were shipped in config/ and seeded once by
# monarch-config-apply. They are now rendered from themes/_templates by
# `monarch theme apply`, and the shipped copies are gone.
#
# Seed-only means monarch-config-apply will not touch the old files, and the
# new engine writes those same three paths — so on any machine that installed
# a pre-T3 checkout, the stale hand-written copies would simply sit there until
# something triggered an apply. This makes that trigger explicit.
#
# Also renders the four apps T3 added — mako, walker, btop, VS Code — which
# never had colour files before.
#
# Nothing has ever been installed from this repository, so this migration is
# very likely a no-op forever. It exists because "very likely" is not the same
# as "certainly", and a migration nobody needs costs nothing.
#
# Run by `monarch migrate` (T7), which records that it has run. Idempotent, so
# running it twice is harmless.

set -euo pipefail

: "${MONARCH_HOME:?migrations run through monarch-migrate; set MONARCH_HOME to run one standalone}"

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
settings="$config_dir/monarch/settings.toml"
apply="$MONARCH_HOME/bin/monarch-theme-apply"

[[ -x "$apply" ]] || { printf 'monarch-theme-apply is missing — nothing to do\n'; exit 0; }

theme="midnight"
if [[ -f "$settings" ]]; then
  found=$(sed -n 's/^[[:space:]]*theme[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$settings" | head -n1)
  [[ -n "$found" ]] && theme=$found
fi

# A theme the user installed and then deleted would leave settings.toml naming
# something that no longer exists. Falling back is better than failing an
# update over a wallpaper.
if [[ ! -f "$MONARCH_HOME/themes/$theme/colors.toml" \
   && ! -f "$config_dir/monarch/themes/$theme/colors.toml" ]]; then
  printf "theme '%s' is not installed — falling back to midnight\n" "$theme"
  theme="midnight"
fi

printf 'Rendering theme %s over the pre-T3 palette files\n' "$theme"
"$apply" "$theme"
