# Load selected environment variables from Bitwarden CLI.
# Config format (default: ~/.bw-env):
#   ENV_VAR|item-id-or-name|password
#   ENV_VAR|item-id-or-name|notes
#   ENV_VAR|item-id-or-name|username
#   ENV_VAR|item-id-or-name|totp
#   ENV_VAR|item-id-or-name|field:Custom Field Name

: "${BW_ENV_FILE:=$HOME/.bw-env}"
: "${BW_ENV_AUTOLOAD:=1}"

_bw_env_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

_bw_env_status() {
  bw status --raw 2>/dev/null | jq -r '.status // empty'
}

_bw_env_item_value() {
  local item_ref="$1"
  local field_name="$2"

  bw get item "$item_ref" 2>/dev/null | jq -r --arg name "$field_name" 'first(.fields[]? | select(.name == $name) | .value) // empty'
}

_bw_env_login_value() {
  local item_ref="$1"
  local jq_filter="$2"

  bw get item "$item_ref" 2>/dev/null | jq -r "${jq_filter} // empty"
}

_bw_env_resolve_value() {
  local item_ref="$1"
  local source_kind="$2"

  case "$source_kind" in
    password)
      bw get password "$item_ref" 2>/dev/null
      ;;
    notes)
      bw get notes "$item_ref" 2>/dev/null
      ;;
    username)
      _bw_env_login_value "$item_ref" '.login.username'
      ;;
    totp)
      bw get totp "$item_ref" 2>/dev/null
      ;;
    field:*)
      _bw_env_item_value "$item_ref" "${source_kind#field:}"
      ;;
    *)
      return 2
      ;;
  esac
}

bwenv_load() {
  local verbose=0
  local env_name item_ref source_kind value
  local loaded_count=0

  if [[ "${1:-}" == "--verbose" ]]; then
    verbose=1
  fi

  if [[ ! -f "$BW_ENV_FILE" ]]; then
    (( verbose )) && printf 'bwenv: config not found: %s\n' "$BW_ENV_FILE" >&2
    return 0
  fi

  if ! command -v bw >/dev/null 2>&1; then
    (( verbose )) && printf 'bwenv: bw command not found\n' >&2
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    (( verbose )) && printf 'bwenv: jq command not found\n' >&2
    return 0
  fi

  if [[ "$(_bw_env_status)" != "unlocked" ]]; then
    (( verbose )) && printf 'bwenv: vault is not unlocked, skip loading\n' >&2
    return 0
  fi

  while IFS='|' read -r env_name item_ref source_kind; do
    env_name="$(_bw_env_trim "$env_name")"
    item_ref="$(_bw_env_trim "$item_ref")"
    source_kind="$(_bw_env_trim "$source_kind")"

    [[ -z "$env_name" || "$env_name" == \#* ]] && continue
    [[ -z "$item_ref" ]] && continue
    [[ -z "$source_kind" ]] && source_kind="password"

    if [[ ! "$env_name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      (( verbose )) && printf 'bwenv: invalid env name: %s\n' "$env_name" >&2
      continue
    fi

    value="$(_bw_env_resolve_value "$item_ref" "$source_kind")" || {
      (( verbose )) && printf 'bwenv: failed to resolve %s from %s (%s)\n' "$env_name" "$item_ref" "$source_kind" >&2
      continue
    }

    [[ -z "$value" ]] && continue
    typeset -gx "$env_name=$value"
    (( loaded_count++ ))
  done <"$BW_ENV_FILE"

  (( verbose )) && printf 'bwenv: loaded %d variable(s)\n' "$loaded_count" >&2
}

bwenv() {
  bwenv_load --verbose
}

bwup() {
  local bw_status session

  if ! command -v bw >/dev/null 2>&1; then
    printf 'bwup: bw command not found\n' >&2
    return 127
  fi

  bw_status="$(_bw_env_status)"
  if [[ "$bw_status" == "unauthenticated" ]]; then
    bw login || return $?
    bw_status="$(_bw_env_status)"
  fi

  if [[ "$bw_status" != "unlocked" ]]; then
    session="$(bw unlock --raw)" || return $?
    export BW_SESSION="$session"
  fi

  bwenv_load --verbose
}

if [[ "$BW_ENV_AUTOLOAD" == "1" ]]; then
  bwenv_load >/dev/null 2>&1
fi
