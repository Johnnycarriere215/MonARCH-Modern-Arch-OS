#!/usr/bin/env bash
#
# Theme engine internals: TOML loading, alias resolution, template rendering.
#
# Not a command — the leading underscore keeps it out of the dispatcher's scan
# and out of the ~/.local/bin symlinks. Source it after _lib.sh, with
# MONARCH_HOME already resolved.
#
# Nothing in here knows the name of an application. Everything app-specific
# lives in themes/_templates/, one file per app, so adding an app to the theme
# system means adding a file and changing no code (T3's actual requirement).

# ------------------------------------------------------------------ layout ---

# Shipped themes, and themes the user installed. User themes win on a name
# clash, so someone can fix a theme we ship without editing the repo.
MONARCH_THEME_DIRS=(
  "$MONARCH_CONFIG_DIR/monarch/themes"
  "$MONARCH_HOME/themes"
)

MONARCH_TEMPLATE_DIR="$MONARCH_HOME/themes/_templates"
MONARCH_SETTINGS="$MONARCH_CONFIG_DIR/monarch/settings.toml"

# key -> value, flattened as "<section>.<key>".
declare -gA THEME=()

# ------------------------------------------------------------------- paths ---

# Absolute path of a theme directory, or failure. Shipped and user themes are
# searched in MONARCH_THEME_DIRS order.
theme_path() {
  local name=$1 dir
  for dir in "${MONARCH_THEME_DIRS[@]}"; do
    [[ -f "$dir/$name/colors.toml" ]] && { printf '%s' "$dir/$name"; return 0; }
  done
  return 1
}

# Every theme name available, deduplicated, sorted.
theme_names() {
  local dir entry
  for dir in "${MONARCH_THEME_DIRS[@]}"; do
    [[ -d "$dir" ]] || continue
    for entry in "$dir"/*/; do
      [[ -f "$entry/colors.toml" ]] || continue
      basename "$entry"
    done
  done | sort -u
}

# Is this theme one we ship? Shipped themes live in the repo and are not the
# user's to delete — an update would just put them back.
theme_is_shipped() {
  [[ -f "$MONARCH_HOME/themes/$1/colors.toml" ]]
}

# ------------------------------------------------------------ TOML loading ---

# Enough TOML for a palette: [sections], key = "value", key = bare, comments.
# Golden rule 6 rules out Python here, and a full parser would be a liability
# for a file format we control both ends of. Anything this cannot parse is
# something a colors.toml has no business containing.
#
# The one subtlety is '#': it opens a comment, and it also opens every colour
# in the file. Quoted values are therefore taken verbatim up to the closing
# quote and never comment-stripped; only bare values lose their tail.
#
#   toml_load <file>   merges into THEME, later calls overriding earlier ones
toml_load() {
  local file=$1 section="" line key value lineno=0
  [[ -f "$file" ]] || { err "no such file: $file"; return 1; }

  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))

    line=${line#"${line%%[![:space:]]*}"}   # ltrim
    [[ -z "$line" || "$line" == \#* ]] && continue

    # [section]
    if [[ "$line" =~ ^\[([A-Za-z0-9_]+)\][[:space:]]*(#.*)?$ ]]; then
      section=${BASH_REMATCH[1]}
      continue
    fi

    # key = value
    if [[ "$line" =~ ^([A-Za-z0-9_]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      key=${BASH_REMATCH[1]}
      value=${BASH_REMATCH[2]}

      if [[ "$value" == \"* ]]; then
        value=${value#\"}
        value=${value%%\"*}
      else
        value=${value%%#*}                       # trailing comment
        value=${value%"${value##*[![:space:]]}"} # rtrim
      fi

      [[ -n "$section" ]] || { err "$file:$lineno: '$key' is outside any [section]"; return 1; }
      THEME["$section.$key"]=$value
      continue
    fi

    err "$file:$lineno: cannot parse: $line"
    return 1
  done <"$file"
}

# ------------------------------------------------------- alias + normalise ---

# "@ui.accent" means "whatever ui.accent ends up being". Resolved after all
# merging, so a theme that overrides ui.accent moves everything pointing at it.
theme_resolve_aliases() {
  local key value hops
  for key in "${!THEME[@]}"; do
    value=${THEME[$key]}
    hops=0
    while [[ "$value" == @* ]]; do
      local target=${value#@}
      [[ -v THEME[$target] ]] || { err "$key -> @$target, which does not exist"; return 1; }
      value=${THEME[$target]}
      hops=$((hops + 1))
      [[ $hops -gt 16 ]] && { err "alias cycle at $key"; return 1; }
    done
    THEME["$key"]=$value
  done
}

# Colours are stored bare and lowercase: 7c6df2. Filters add whatever syntax
# the consuming app wants, so exactly one representation lives in the table.
theme_normalise_colours() {
  local key value bare
  for key in "${!THEME[@]}"; do
    value=${THEME[$key]}
    bare=${value#\#}

    if [[ "$value" == \#* ]]; then
      # An explicit '#' is a claim that this is a colour. Hold it to it.
      if [[ ! "$bare" =~ ^[0-9a-fA-F]{6}$ ]]; then
        err "$key = '$value' is not a 6-digit hex colour (short form is not accepted)"
        return 1
      fi
    else
      # No '#': only treat it as a colour if it unambiguously is one.
      [[ "$bare" =~ ^[0-9a-fA-F]{6}$ ]] || continue
    fi

    THEME["$key"]=${bare,,}
  done
}

# Every key the schema leaves empty is required — the schema states the floor
# by leaving a hole in it, so adding a required field means editing one file.
# meta.* is exempt: a theme without a description is fine, and meta.name comes
# from the directory.
#
# Filled by theme_load while the schema is loaded and nothing else is.
THEME_REQUIRED=()

theme_validate() {
  local key missing=()

  for key in "${THEME_REQUIRED[@]}"; do
    [[ -n "${THEME[$key]:-}" ]] || missing+=("$key")
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    local m
    err "theme is missing ${#missing[@]} required value(s):"
    while IFS= read -r m; do printf '        %s\n' "$m" >&2; done \
      < <(printf '%s\n' "${missing[@]}" | sort)
    return 1
  fi

  # A required value that survived normalisation without becoming a colour.
  for key in "${THEME_REQUIRED[@]}"; do
    [[ "${THEME[$key]}" =~ ^[0-9a-f]{6}$ ]] && continue
    err "$key = '${THEME[$key]}' is not a colour"
    return 1
  done
  return 0
}

# The whole load: schema defaults, then the theme, then resolve and check.
theme_load() {
  local dir=$1 name=$2 key
  THEME=()
  toml_load "$MONARCH_HOME/schema/theme.toml" || return 1

  THEME_REQUIRED=()
  for key in "${!THEME[@]}"; do
    [[ "$key" == meta.* ]] && continue
    [[ -z "${THEME[$key]}" ]] && THEME_REQUIRED+=("$key")
  done

  toml_load "$dir/colors.toml" || return 1

  # The directory name wins. A colors.toml whose meta.name disagrees is a
  # copied theme someone forgot to rename, and every other command keys off
  # the directory.
  if [[ -n "${THEME[meta.name]:-}" && "${THEME[meta.name]}" != "$name" ]]; then
    warn "meta.name is '${THEME[meta.name]}' but the directory is '$name' — using '$name'"
  fi
  THEME[meta.name]=$name

  theme_resolve_aliases || return 1
  theme_normalise_colours || return 1
  theme_validate || return 1
}

# --------------------------------------------------------------- rendering ---

# One palette value, in whatever syntax the asking app speaks.
theme_value() {
  local key=$1 filter=${2:-} arg=${3:-} v

  if [[ ! -v THEME[$key] ]]; then
    err "template asked for {{$key}}, which no theme defines"
    return 1
  fi
  v=${THEME[$key]}

  # Non-colours (names, booleans, descriptions) ignore filters and pass
  # through. Filtering a string is always a template bug, so say so.
  if [[ ! "$v" =~ ^[0-9a-f]{6}$ ]]; then
    [[ -n "$filter" ]] && { err "{{$key|$filter}}: '$v' is not a colour"; return 1; }
    printf '%s' "$v"
    return 0
  fi

  case "$filter" in
    ""|hex)  printf '#%s' "$v" ;;
    raw)     printf '%s' "$v" ;;
    rgb)     printf 'rgb(%s)' "$v" ;;
    rgba)    printf 'rgba(%s%s)' "$v" "${arg:-ff}" ;;
    hexa)    printf '#%s%s' "$v" "${arg:-ff}" ;;
    css)     printf 'rgba(%d, %d, %d, %s)' \
               "0x${v:0:2}" "0x${v:2:2}" "0x${v:4:2}" "${arg:-1}" ;;
    *)       err "{{$key|$filter}}: unknown filter '$filter'"; return 1 ;;
  esac
}

# A template's #! header. Lines beginning with #! are metadata and never reach
# the output, which keeps the mechanism syntax-agnostic — it works identically
# in a .css, a .toml and a .json, none of which share a comment character.
template_meta() {
  local file=$1 field=$2
  sed -n "s|^#![[:space:]]*$field:[[:space:]]*||p" "$file"
}

# Render one template to stdout. Fails on an unknown key or filter rather than
# emitting a file with a hole in it.
template_render() {
  local file=$1 line out rest whole key filter arg value

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == '#!'* ]] && continue

    out=""
    rest=$line
    while [[ "$rest" =~ \{\{([A-Za-z0-9_.]+)(\|([a-z]+)(:([0-9a-fA-F.]+))?)?\}\} ]]; do
      whole=${BASH_REMATCH[0]}
      key=${BASH_REMATCH[1]}
      filter=${BASH_REMATCH[3]}
      arg=${BASH_REMATCH[5]}
      value=$(theme_value "$key" "$filter" "$arg") || {
        err "  in $(basename "$file")"
        return 1
      }
      out+="${rest%%"$whole"*}$value"
      rest=${rest#*"$whole"}
    done

    printf '%s%s\n' "$out" "$rest"
  done <"$file"
}

# A template's target, as an absolute path. Bare paths are relative to
# ~/.config; a leading ~/ escapes it, which VS Code needs.
template_target() {
  local raw=$1
  case "$raw" in
    '~/'*) printf '%s/%s' "$HOME" "${raw#\~/}" ;;
    /*)    printf '%s' "$raw" ;;
    *)     printf '%s/%s' "$MONARCH_CONFIG_DIR" "$raw" ;;
  esac
}

# ---------------------------------------------------------------- settings ---

# The active theme, from settings.toml. Golden rule 2: the TOML is the truth,
# the rendered files are output. If settings.toml is unreadable we say so
# rather than guessing, because guessing here means silently reverting a theme.
settings_theme() {
  local value
  [[ -f "$MONARCH_SETTINGS" ]] || return 1
  value=$(sed -n 's/^[[:space:]]*theme[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$MONARCH_SETTINGS" | head -n1)
  [[ -n "$value" ]] || return 1
  printf '%s' "$value"
}

# Rewrite one scalar key in settings.toml in place, preserving everything else
# — comments included. The CLI is the only thing that writes config, and it
# does not get to reformat the user's file to do it.
settings_set() {
  local key=$1 value=$2 tmp
  [[ -f "$MONARCH_SETTINGS" ]] || { warn "no settings.toml — not recording $key"; return 0; }

  grep -q "^[[:space:]]*$key[[:space:]]*=" "$MONARCH_SETTINGS" || {
    warn "settings.toml has no '$key' key — not adding one"
    return 0
  }

  tmp=$(mktemp)
  awk -v k="$key" -v v="$value" '
    !done && $0 ~ "^[[:space:]]*" k "[[:space:]]*=" {
      print k " = \"" v "\""; done = 1; next
    }
    { print }
  ' "$MONARCH_SETTINGS" >"$tmp"
  cat "$tmp" >"$MONARCH_SETTINGS"
  rm -f "$tmp"
}
