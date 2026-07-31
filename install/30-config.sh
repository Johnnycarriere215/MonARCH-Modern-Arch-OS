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
  local src="$MONARCH_HOME/config"
  local dst="${XDG_CONFIG_HOME:-$HOME/.config}"

  [[ -d "$src" ]] || { warn "no config/ directory in $MONARCH_HOME — skipping"; return 0; }

  info "Deploying configs to $dst"
  mkdir -p "$dst"

  local count=0 file rel
  while IFS= read -r file; do
    rel=${file#"$src"/}
    deploy_user_file "$file" "$dst/$rel"
    count=$((count + 1))
  done < <(find "$src" -type f ! -name '.gitkeep' | sort)

  if [[ $count -eq 0 ]]; then
    ok "no config files to deploy yet (T2 adds them)"
  else
    ok "$count config files deployed"
  fi
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
  stage_30_link_cli
  stage_30_path
}

stage_30_config
