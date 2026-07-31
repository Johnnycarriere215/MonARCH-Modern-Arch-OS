#!/usr/bin/env bash
#
# Shared by monarch-startup-{list,add,remove}.
#
# The managed block in autostart-user.conf is the single source of truth for
# which apps start with the session. settings.toml's `startup_apps` is a mirror
# kept in step on every write, so the GUI can read a TOML array instead of
# parsing Hyprland syntax. If the two ever disagree, the .conf wins.

STARTUP_FILE="$MONARCH_CONFIG_DIR/hypr/autostart-user.conf"
SETTINGS_FILE="$MONARCH_CONFIG_DIR/monarch/settings.toml"

START_MARKER='# >>> monarch startup apps >>>'
END_MARKER='# <<< monarch startup apps <<<'

# The file is seeded by monarch-config-apply. If someone deleted it, rebuild
# the skeleton rather than failing — an empty startup list is a valid state.
ensure_startup_file() {
  if [[ ! -f "$STARTUP_FILE" ]]; then
    mkdir -p "$(dirname "$STARTUP_FILE")"
    {
      printf '# MonARCH — your startup apps\n'
      printf '#\n# Managed by: monarch startup add|remove|list\n\n'
      printf '%s\n%s\n' "$START_MARKER" "$END_MARKER"
    } >"$STARTUP_FILE"
    return 0
  fi

  # File exists but the markers were lost to a bad hand-edit. Append a fresh
  # block instead of writing nowhere.
  if ! grep -qF "$START_MARKER" "$STARTUP_FILE"; then
    printf '\n%s\n%s\n' "$START_MARKER" "$END_MARKER" >>"$STARTUP_FILE"
  fi
}

# The commands currently inside the managed block, one per line.
read_startup_apps() {
  [[ -f "$STARTUP_FILE" ]] || return 0
  awk -v s="$START_MARKER" -v e="$END_MARKER" '
    $0 == s { inside = 1; next }
    $0 == e { inside = 0; next }
    inside
  ' "$STARTUP_FILE" \
  | sed -n 's/^[[:space:]]*exec-once[[:space:]]*=[[:space:]]*//p'
}

# Replace the managed block with exactly the commands given on stdin.
write_startup_apps() {
  local apps=("$@")
  local tmp; tmp=$(mktemp)

  local body; body=$(mktemp)
  local a
  for a in ${apps+"${apps[@]}"}; do
    printf 'exec-once = %s\n' "$a" >>"$body"
  done

  awk -v s="$START_MARKER" -v e="$END_MARKER" -v body="$body" '
    $0 == s {
      print
      while ((getline line < body) > 0) print line
      close(body)
      skipping = 1
      next
    }
    $0 == e { skipping = 0 }
    !skipping
  ' "$STARTUP_FILE" >"$tmp"

  mv "$tmp" "$STARTUP_FILE"
  rm -f "$body"

  sync_settings_mirror "${apps[@]+"${apps[@]}"}"
}

# Keep settings.toml's startup_apps array in step with the .conf.
# Written inline in bash — no Python, no TOML library (golden rule 6).
sync_settings_mirror() {
  local apps=("$@")
  [[ -f "$SETTINGS_FILE" ]] || return 0

  local array="startup_apps = ["
  if [[ ${#apps[@]} -gt 0 ]]; then
    local first=true a escaped
    for a in "${apps[@]}"; do
      # Escape backslashes then double quotes, in that order.
      escaped=${a//\\/\\\\}
      escaped=${escaped//\"/\\\"}
      if [[ "$first" == true ]]; then
        array+="\"$escaped\""
        first=false
      else
        array+=", \"$escaped\""
      fi
    done
  fi
  array+="]"

  local tmp; tmp=$(mktemp)
  if grep -q '^[[:space:]]*startup_apps[[:space:]]*=' "$SETTINGS_FILE"; then
    # awk rather than sed: the value can contain slashes and & , both of which
    # sed would treat as syntax.
    awk -v repl="$array" '
      /^[[:space:]]*startup_apps[[:space:]]*=/ { print repl; next }
      { print }
    ' "$SETTINGS_FILE" >"$tmp"
  else
    cat "$SETTINGS_FILE" >"$tmp"
    printf '\n%s\n' "$array" >>"$tmp"
  fi
  mv "$tmp" "$SETTINGS_FILE"
}

# Ask Hyprland to re-read config so the change is live, when there is a session.
reload_hyprland() {
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && have hyprctl; then
    hyprctl reload >/dev/null 2>&1 || true
  fi
}
