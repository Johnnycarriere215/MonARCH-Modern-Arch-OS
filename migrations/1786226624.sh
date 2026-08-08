#!/usr/bin/env bash
#DESC: Brand the system — os-release, /etc/issue, greeter, fastfetch
#
# Golden rule 5: every behaviour change ships a migration.
#
# install/45-branding.sh is new, so a machine installed before it exists still
# calls itself "Arch Linux" at the login prompt and in fastfetch. Re-running
# the stage fixes that; it is idempotent and compares before every write.
#
# The greetd greeting is NOT handled here. It lives in stage 40's heredoc, and
# /etc/greetd/config.toml is a system file the user may have edited — rewriting
# it from a migration risks replacing a working login screen with a broken one.
# Stage 45 reports on it instead, and re-running the installer sets it.

set -euo pipefail

: "${MONARCH_HOME:?migrations run through monarch-migrate; set MONARCH_HOME to run one standalone}"

stage="$MONARCH_HOME/install/45-branding.sh"

[[ -f "$stage" ]] || { printf 'no branding stage — nothing to do\n'; exit 0; }

# Already branded? Nothing to do, and this keeps the migration silent on a
# fresh install where stage 45 has just run.
if grep -q '^ID=monarch' /etc/os-release 2>/dev/null; then
  printf 'already branded\n'
  exit 0
fi

printf 'Branding the system — this needs sudo\n'

# The stage is written to be sourced by bootstrap.sh, which supplies the output
# helpers from install/_common.sh. Source that first so it can stand alone.
# shellcheck source=/dev/null
source "$MONARCH_HOME/install/_common.sh"
# shellcheck source=/dev/null
source "$stage"
