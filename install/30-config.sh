#!/usr/bin/env bash
#DESC: Stage 30 — deploy config/ to ~/.config and put the monarch CLI on PATH
#
# Sourced by bootstrap.sh. Safe to re-run: identical files are skipped, and a
# file you have edited yourself is moved to .bak rather than overwritten.
#
# config/ is still mostly empty at T1 — T2 fills it. The deploy logic lives here
# now so that T2 is only a matter of adding files.

: "${MONARCH_HOME:?install stages run through bootstrap.sh; set MONARCH_HOME to run one standalone}"

# shellcheck source=/dev/null
source "$MONARCH_HOME/install/_common.sh"

stage_30_deploy_configs() {
  # Golden rule 1: the monarch CLI is the only thing that writes config. The
  # installer is not an exception — it shells out like everything else, so the
  # first deploy and every later `monarch config apply` take the identical path
  # and there is only one set of behaviour to get right.
  local apply="$MONARCH_HOME/bin/monarch-config-apply"

  [[ -x "$apply" ]] || die "missing $apply — cannot deploy configuration"

  info "Deploying configs"
  MONARCH_HOME="$MONARCH_HOME" "$apply" --quiet \
    || die "config deploy failed"
}

stage_30_apply_theme() {
  # The colour files under ~/.config/monarch/theme are GENERATED, and since T3
  # they are generated here rather than shipped in config/. There is exactly
  # one producer of a palette — themes/_templates — and no checked-in copy to
  # drift away from it.
  #
  # Fatal on failure, deliberately: config/hypr/hyprland.conf sources
  # hypr-colors.conf, so a session with no palette is a session that does not
  # start. Better to stop the install where the reason is still on screen.
  local apply="$MONARCH_HOME/bin/monarch-theme-apply"
  local settings="${XDG_CONFIG_HOME:-$HOME/.config}/monarch/settings.toml"

  [[ -x "$apply" ]] || die "missing $apply — cannot render the theme"

  # settings.toml was just seeded by the deploy above, so this normally reads
  # the shipped default. On a re-run it reads whatever the user has chosen,
  # which is the point: an update must not silently reset the theme.
  local theme="midnight"
  if [[ -f "$settings" ]]; then
    theme=$(sed -n 's/^[[:space:]]*theme[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' \
      "$settings" | head -n1)
    [[ -n "$theme" ]] || theme="midnight"
  fi

  # --no-reload: nothing is running yet on a first install, and on a re-run
  # hyprctl would be poking the session the installer is sitting inside.
  MONARCH_HOME="$MONARCH_HOME" "$apply" "$theme" --no-reload \
    || die "could not render theme '$theme'"
}

stage_30_apply_keys() {
  # bindings.conf is generated, for the same reason the palette is: one
  # producer, no shipped copy to drift from it. Fatal on failure — hyprland.conf
  # sources bindings.conf, and a session you cannot open a terminal in is not a
  # session.
  local apply="$MONARCH_HOME/bin/monarch-keys-apply"
  [[ -x "$apply" ]] || die "missing $apply — cannot generate keybindings"

  info "Generating keybindings"
  # --no-reload for the same reason as the theme: on a re-run hyprctl would be
  # poking the session the installer is sitting inside.
  MONARCH_HOME="$MONARCH_HOME" "$apply" --no-reload \
    || die "could not generate keybindings"
}

stage_30_apply_bar() {
  # modules-enabled.jsonc and the modules-active.jsonc symlink are generated,
  # for the same reason the palette and the keymap are. Not fatal, unlike those
  # two: Waybar with a missing include logs a warning and carries on, so a
  # failure here costs you the stats, not the session.
  local apply="$MONARCH_HOME/bin/monarch-bar-modules"
  [[ -x "$apply" ]] || { warn "missing $apply — skipping bar modules"; return 0; }

  info "Configuring bar modules"
  MONARCH_HOME="$MONARCH_HOME" "$apply" reset \
    || warn "could not configure bar modules — the bar will start without stats"
}

stage_30_apply_mode() {
  # mode.conf, mode-session.conf and the bar's mode-overrides.jsonc are all
  # generated. hyprland.conf sources the first two unconditionally, and
  # config.jsonc now takes its position/height/left/center from the third — so
  # this has to run, and it runs after the bar so the mode has the last word on
  # which stats variant is in use.
  local apply="$MONARCH_HOME/bin/monarch-mode-set"
  [[ -x "$apply" ]] || die "missing $apply — cannot set the desktop mode"

  local settings="${XDG_CONFIG_HOME:-$HOME/.config}/monarch/settings.toml"
  local mode="tiling"
  if [[ -f "$settings" ]]; then
    mode=$(sed -n 's/^[[:space:]]*mode[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' \
      "$settings" | head -n1)
    [[ -n "$mode" ]] || mode="tiling"
  fi

  info "Setting desktop mode: $mode"
  # --no-plugins: hyprpm compiles against the RUNNING Hyprland and there is no
  # session during an install. Windows mode picks its plugin up at first use.
  MONARCH_HOME="$MONARCH_HOME" "$apply" "$mode" --no-reload --no-plugins \
    || die "could not set mode '$mode'"
}

stage_30_link_cli() {
  local bindir="$HOME/.local/bin"
  info "Linking the monarch CLI into $bindir"
  mkdir -p "$bindir"

  local linked=0 script name
  while IFS= read -r script; do
    name=$(basename "$script")
    # Symlink, not copy: `monarch update` pulls the repo and the CLI is then
    # current with no reinstall step.
    ln -sfn "$script" "$bindir/$name"
    linked=$((linked + 1))
  done < <(find "$MONARCH_HOME/bin" -maxdepth 1 -type f -name 'monarch*' | sort)

  [[ $linked -gt 0 ]] || die "No monarch scripts found in $MONARCH_HOME/bin"
  ok "$linked commands linked"
}

stage_30_path() {
  # ~/.local/bin is on PATH by default under systemd's user environment on most
  # setups, but not in a plain bash login shell. Make it explicit and do it once.
  # ensure_line_in_file writes the marker itself — passing it in the body too
  # would print it twice.
  local marker='# added by MonARCH — keeps the monarch CLI on PATH'
  ensure_line_in_file "$HOME/.bashrc" "$marker" \
    'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac'
  ok "PATH configured"
}

stage_30_state_dirs() {
  # Where mode/theme/channel end up. Created now so T3/T6/T7 can assume them and
  # so monarch-doctor has somewhere to look.
  mkdir -p "$HOME/.local/state/monarch"
  mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/monarch"
  ok "state directories ready"
}

stage_30_config() {
  stage_30_state_dirs
  stage_30_deploy_configs
  # After the deploy: settings.toml has to exist before we can read a theme
  # name out of it.
  stage_30_apply_theme
  stage_30_apply_keys
  stage_30_apply_bar
  stage_30_apply_mode
  stage_30_link_cli
  stage_30_path
}

stage_30_config
