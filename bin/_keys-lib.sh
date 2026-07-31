#!/usr/bin/env bash
#
# Keybind internals: loading keybinds.toml, normalising combinations, and
# generating Hyprland's bindings.conf.
#
# Not a command — the leading underscore keeps it out of the dispatcher's scan
# and out of the ~/.local/bin symlinks. Source it after _lib.sh, with
# MONARCH_HOME already resolved.
#
# Golden rule 2: keybinds.toml is the source of truth, bindings.conf is output.
# Nothing here ever reads bindings.conf.

# ------------------------------------------------------------------- paths ---

MONARCH_KEYBINDS_USER="$MONARCH_CONFIG_DIR/monarch/keybinds.toml"
MONARCH_KEYBINDS_DEFAULT="$MONARCH_HOME/schema/keybinds.toml"
MONARCH_BINDINGS_OUT="$MONARCH_CONFIG_DIR/hypr/bindings.conf"

# The user's keymap if they have one, ours if they do not. An update improves
# the defaults for everyone who has never touched theirs, and touches nobody
# else's.
keybinds_source() {
  if [[ -f "$MONARCH_KEYBINDS_USER" ]]; then
    printf '%s' "$MONARCH_KEYBINDS_USER"
  else
    printf '%s' "$MONARCH_KEYBINDS_DEFAULT"
  fi
}

# -------------------------------------------------------------- the records ---

# Parallel arrays rather than one associative array per bind: bash has no
# nested structures, and parallel arrays keep the file's order, which is the
# order `keys list` and the generated file both want.
BIND_ID=(); BIND_KEYS=(); BIND_DISPATCHER=(); BIND_ACTION=()
BIND_ARGS=(); BIND_GROUP=(); BIND_LABEL=(); BIND_EDITABLE=(); BIND_FLAGS=()

# name -> value, from [vars]. Emitted as $name at the top of the generated file.
declare -gA KEYVARS=()
KEYVAR_ORDER=()

# Enough TOML for a keymap: [vars], [[bind]] arrays-of-tables, key = "value".
# Golden rule 6 rules out Python. The theme engine's toml_load in _theme-lib.sh
# does flat sections only, which is why this is a separate parser rather than a
# shared one — arrays-of-tables need to know when a record ends.
keybinds_load() {
  local file=$1 line lineno=0 section="" in_bind=false
  local key value

  [[ -f "$file" ]] || { err "no such file: $file"; return 1; }

  BIND_ID=(); BIND_KEYS=(); BIND_DISPATCHER=(); BIND_ACTION=()
  BIND_ARGS=(); BIND_GROUP=(); BIND_LABEL=(); BIND_EDITABLE=(); BIND_FLAGS=()
  KEYVARS=(); KEYVAR_ORDER=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))

    line=${line#"${line%%[![:space:]]*}"}   # ltrim
    [[ -z "$line" || "$line" == \#* ]] && continue

    # [[bind]] — start a new record, with the defaults every field falls back to.
    if [[ "$line" =~ ^\[\[([A-Za-z0-9_]+)\]\] ]]; then
      [[ "${BASH_REMATCH[1]}" == "bind" ]] || {
        err "$file:$lineno: unknown array [[${BASH_REMATCH[1]}]]"; return 1; }
      section="bind"; in_bind=true
      BIND_ID+=("");        BIND_KEYS+=("")
      BIND_DISPATCHER+=(""); BIND_ACTION+=("")
      BIND_ARGS+=("");      BIND_GROUP+=("Other")
      BIND_LABEL+=("");     BIND_EDITABLE+=("true")
      BIND_FLAGS+=("")
      continue
    fi

    if [[ "$line" =~ ^\[([A-Za-z0-9_]+)\] ]]; then
      section=${BASH_REMATCH[1]}; in_bind=false
      continue
    fi

    [[ "$line" =~ ^([A-Za-z0-9_]+)[[:space:]]*=[[:space:]]*(.*)$ ]] || {
      err "$file:$lineno: cannot parse: $line"; return 1; }
    key=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}

    if [[ "$value" == \"* ]]; then
      # Take everything up to the LAST quote on the line, so an action
      # containing an escaped quote — grim -g "$(slurp)" — survives intact.
      value=${value#\"}
      value=${value%\"*}
      value=${value//\\\"/\"}
    else
      value=${value%%#*}
      value=${value%"${value##*[![:space:]]}"}
    fi

    if [[ "$section" == "vars" ]]; then
      [[ -v KEYVARS[$key] ]] || KEYVAR_ORDER+=("$key")
      KEYVARS["$key"]=$value
      continue
    fi

    [[ "$in_bind" == true ]] || {
      err "$file:$lineno: '$key' is outside [vars] and outside any [[bind]]"; return 1; }

    local i=$(( ${#BIND_ID[@]} - 1 ))
    case "$key" in
      id)         BIND_ID[i]=$value ;;
      keys)       BIND_KEYS[i]=$value ;;
      dispatcher) BIND_DISPATCHER[i]=$value ;;
      action)     BIND_ACTION[i]=$value ;;
      args)       BIND_ARGS[i]=$value ;;
      group)      BIND_GROUP[i]=$value ;;
      label)      BIND_LABEL[i]=$value ;;
      editable)   BIND_EDITABLE[i]=$value ;;
      flags)      BIND_FLAGS[i]=$value ;;
      *) err "$file:$lineno: unknown field '$key' — see schema/keybinds.toml"; return 1 ;;
    esac
  done <"$file"

  [[ ${#BIND_ID[@]} -gt 0 ]] || { err "$file defines no bindings"; return 1; }
  keybinds_validate "$file"
}

keybinds_validate() {
  local file=$1 i bad=0

  for i in "${!BIND_ID[@]}"; do
    local where="[[bind]] #$((i + 1))"
    [[ -n "${BIND_ID[i]}" ]] && where="'${BIND_ID[i]}'"

    [[ -n "${BIND_ID[i]}" ]]   || { err "$where has no id"; bad=1; }
    [[ -n "${BIND_KEYS[i]}" ]] || { err "$where has no keys"; bad=1; }
    [[ -n "${BIND_ACTION[i]}" ]] || { err "$where has no action"; bad=1; }

    case "${BIND_DISPATCHER[i]}" in
      hyprctl|exec) ;;
      "") err "$where has no dispatcher (hyprctl or exec)"; bad=1 ;;
      *)  err "$where: dispatcher must be hyprctl or exec, not '${BIND_DISPATCHER[i]}'"; bad=1 ;;
    esac

    # "MODS, KEY" or ", KEY". A missing comma is the mistake people make.
    [[ "${BIND_KEYS[i]}" == *,* ]] \
      || { err "$where: keys must be \"MODS, KEY\" — '${BIND_KEYS[i]}' has no comma"; bad=1; }

    [[ "${BIND_FLAGS[i]}" =~ ^[relm]*$ ]] \
      || { err "$where: flags may only contain r, e, l and m"; bad=1; }

    case "${BIND_EDITABLE[i]}" in
      true|false) ;;
      *) err "$where: editable must be true or false"; bad=1 ;;
    esac
  done

  [[ $bad -eq 0 ]] || { err "in $file"; return 1; }
}

# ------------------------------------------------------------- normalisation ---

# One canonical spelling of a combination, so that "SUPER SHIFT, Return" and
# "shift super, RETURN" are recognised as the same key. Modifiers sorted
# alphabetically, key upper-cased, joined with '+'.
#
# Used only for comparison. Never written to a config.
combo_normalise() {
  local raw=$1
  local mods=${raw%%,*}
  local key=${raw#*,}

  key=${key//[[:space:]]/}
  mods=${mods^^}

  local sorted=""
  if [[ -n "${mods// /}" ]]; then
    sorted=$(printf '%s\n' $mods | sort -u | paste -sd'+' -)
  fi

  if [[ -n "$sorted" ]]; then
    printf '%s+%s' "$sorted" "${key^^}"
  else
    printf '%s' "${key^^}"
  fi
}

# How a combination should be shown to a person: SUPER + SHIFT + Return.
# Keeps the key's original case, because 'Return' and 'XF86AudioPlay' are names,
# not shouting.
combo_display() {
  local raw=$1
  local mods=${raw%%,*}
  local key=${raw#*,}

  key=${key//[[:space:]]/}
  mods=${mods^^}
  mods=${mods//[[:space:]]/ }

  local out=""
  local m
  for m in $mods; do out+="$m + "; done
  printf '%s%s' "$out" "$key"
}

# ---------------------------------------------------------------- generation ---

# The Hyprland `bind` line for one record.
bind_line() {
  local i=$1
  local mods=${BIND_KEYS[i]%%,*}
  local key=${BIND_KEYS[i]#*,}

  mods=${mods#"${mods%%[![:space:]]*}"}
  mods=${mods%"${mods##*[![:space:]]}"}
  key=${key#"${key%%[![:space:]]*}"}
  key=${key%"${key##*[![:space:]]}"}

  # $mod rather than a literal SUPER, so someone who wants the Alt key changes
  # one variable instead of forty lines.
  if [[ -n "${KEYVARS[mod]:-}" && "${mods^^}" == "${KEYVARS[mod]^^}"* ]]; then
    mods="\$mod${mods:${#KEYVARS[mod]}}"
  fi

  local word args
  if [[ "${BIND_DISPATCHER[i]}" == "exec" ]]; then
    word="exec"
    args=${BIND_ACTION[i]}
  else
    word=${BIND_ACTION[i]}
    args=${BIND_ARGS[i]}
  fi

  printf 'bind%s = %s, %s, %s' "${BIND_FLAGS[i]}" "$mods" "$key" "$word"
  # No trailing comma when there is no argument. Hyprland tolerates
  # `killactive,` but bindm takes no parameter at all, and one rule that is
  # right everywhere beats two that are each right somewhere.
  [[ -n "$args" ]] && printf ', %s' "$args"
  printf '\n'
}

# The whole bindings.conf, to stdout.
bindings_render() {
  local source=$1

  cat <<EOF
# GENERATED BY MONARCH — DO NOT EDIT
#
# Source:      ${source/#$HOME/\~}
# Regenerate:  monarch keys apply
#
# Edits to this file survive until the next \`monarch keys apply\`, and then they
# do not. Change the keymap in the source above, or through the settings GUI,
# which shells out to the same command.
#
# $(printf '%s' "${#BIND_ID[@]}") bindings.

EOF

  local name
  for name in "${KEYVAR_ORDER[@]}"; do
    printf '$%-8s = %s\n' "$name" "${KEYVARS[$name]}"
  done
  printf '\n'

  # Grouped, in the order the groups first appear in the source, so the
  # generated file reads in the same order as the file it came from.
  local groups=() seen=" " i g
  for i in "${!BIND_ID[@]}"; do
    g=${BIND_GROUP[i]}
    [[ "$seen" == *" $g "* ]] && continue
    groups+=("$g"); seen+="$g "
  done

  for g in "${groups[@]}"; do
    printf '# %s %s\n' "$(printf '%.0s═' {1..60})" "$g"
    for i in "${!BIND_ID[@]}"; do
      [[ "${BIND_GROUP[i]}" == "$g" ]] || continue
      bind_line "$i"
    done
    printf '\n'
  done
}
