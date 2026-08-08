#!/usr/bin/env bash
#DESC: Stage 50 — print the summary and offer a reboot
#
# Sourced by bootstrap.sh. Safe to re-run.

: "${MONARCH_HOME:?install stages run through bootstrap.sh; set MONARCH_HOME to run one standalone}"

# shellcheck source=/dev/null
source "$MONARCH_HOME/install/_common.sh"

# The wordmark, if the terminal can render it. brand/monarch.ascii is drawn
# with block and shade characters (█ ▓ ▒ ░), which a console font without full
# box-drawing coverage turns into a rectangle of tofu — worse than no banner at
# all. UTF-8 locale is the cheap proxy for "this will probably look right".
stage_50_banner() {
  local art="$MONARCH_HOME/brand/monarch.ascii"
  [[ -r "$art" ]] || return 0
  [[ "${LANG:-}${LC_ALL:-}" == *[Uu][Tt][Ff]* ]] || return 0
  printf '\n'
  cat "$art"
}

stage_50_summary() {
  local version="unknown"
  [[ -r "$MONARCH_HOME/version" ]] && version=$(<"$MONARCH_HOME/version")

  cat <<EOF

  ────────────────────────────────────────────────────────────
   MonARCH ${version} installed
  ────────────────────────────────────────────────────────────

   Source tree   $MONARCH_HOME
   Install log   ${MONARCH_LOG:-/var/log/monarch-install.log}
   CLI           monarch          (try: monarch doctor)

   Next boot brings up greetd. Pick Hyprland and log in.

   Super           launcher
   Super+Return    terminal
   Super+/         every keybinding

   The editor is not installed yet — it builds from source:
     monarch install monarch-code

EOF
}

stage_50_doctor() {
  # Best effort. The CLI is symlinked into ~/.local/bin, which is not on this
  # shell's PATH until the next login, so call it by path.
  local doctor="$MONARCH_HOME/bin/monarch-doctor"
  if [[ -x "$doctor" ]]; then
    info "System report"
    "$doctor" || warn "monarch-doctor exited non-zero — not fatal"
  fi
}

stage_50_reboot_prompt() {
  # bootstrap.sh is usually run as `curl ... | bash`, which means stdin is the
  # script itself, not the keyboard. Read from the terminal directly, and skip
  # the prompt entirely when there is no terminal (CI, ISO, automation).
  if [[ ! -r /dev/tty ]] || [[ -n "${MONARCH_NO_REBOOT_PROMPT:-}" ]]; then
    info "Non-interactive — not offering a reboot. Reboot when ready."
    return 0
  fi

  local answer=""
  printf '\n  Reboot into MonARCH now? [y/N] '
  read -r answer </dev/tty || answer=""
  printf '\n'

  case "${answer,,}" in
    y|yes)
      info "Rebooting"
      sudo systemctl reboot
      ;;
    *)
      info "Not rebooting. Run 'sudo reboot' when you are ready."
      ;;
  esac
}

stage_50_finish() {
  stage_50_banner
  stage_50_summary
  stage_50_doctor
  stage_50_reboot_prompt
}

stage_50_finish
