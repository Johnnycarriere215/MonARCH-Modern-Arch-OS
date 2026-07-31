#!/usr/bin/env bash
#DESC: T5 — generate the bar's module list and add bar_modules to settings.toml
#
# Golden rule 5: every behaviour change ships a migration.
#
# Before T5, config.jsonc carried its own "modules-right" and there were no
# system stats. Now it carries an "include" instead, and the list lives in
# ~/.config/waybar/modules-enabled.jsonc, generated from bar_modules in
# settings.toml.
#
# Two things need doing on a machine that installed a pre-T5 checkout:
#
#   1. settings.toml is seed-only, so the new bar_modules key will never arrive
#      on its own. monarch-bar-modules appends it when it is missing.
#   2. modules-enabled.jsonc and the modules-active.jsonc symlink do not exist,
#      so the bar would come up with no right-hand group at all — config.jsonc
#      no longer defines one.
#
# `monarch bar modules reset` does both. Idempotent.
#
# Not fatal on failure: a bar with no stats is a working bar.

set -euo pipefail

: "${MONARCH_HOME:?migrations run through monarch-migrate; set MONARCH_HOME to run one standalone}"

apply="$MONARCH_HOME/bin/monarch-bar-modules"

[[ -x "$apply" ]] || { printf 'monarch-bar-modules is missing — nothing to do\n'; exit 0; }

# Someone who has already customised their bar should keep their choices. Only
# reset when there is nothing to preserve.
settings="${XDG_CONFIG_HOME:-$HOME/.config}/monarch/settings.toml"
enabled="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/modules-enabled.jsonc"

if [[ -f "$enabled" ]] && grep -q '^[[:space:]]*bar_modules' "$settings" 2>/dev/null; then
  printf 'bar modules already configured — leaving your list alone\n'
  exit 0
fi

printf 'Generating the bar module list\n'
"$apply" reset || printf 'could not configure bar modules — the bar will start without stats\n'
