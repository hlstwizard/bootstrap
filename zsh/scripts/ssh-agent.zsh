if [[ -o interactive ]]; then
  typeset -g SSH_AGENT_HOSTNAME="${SSH_AGENT_HOSTNAME:-${HOST%%.*}}"
  typeset -g SSH_AGENT_ENV_DIR="${SSH_AGENT_ENV_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/ssh-agent}"
  typeset -g SSH_AGENT_ENV_FILE="${SSH_AGENT_ENV_FILE:-${SSH_AGENT_ENV_DIR}/agent-${SSH_AGENT_HOSTNAME}.env}"

  _ssh_agent_load_env() {
    [[ -r "$SSH_AGENT_ENV_FILE" ]] || return 1
    source "$SSH_AGENT_ENV_FILE" >/dev/null 2>&1
  }

  _ssh_agent_check() {
    [[ -n "${SSH_AUTH_SOCK:-}" ]] || return 1
    [[ -S "$SSH_AUTH_SOCK" ]] || return 1
    ssh-add -l >/dev/null 2>&1
    case "$?" in
      0|1) return 0 ;;
      *) return 1 ;;
    esac
  }

  _ssh_agent_start() {
    mkdir -p "$SSH_AGENT_ENV_DIR"
    umask 077
    ssh-agent -s >| "$SSH_AGENT_ENV_FILE"
    source "$SSH_AGENT_ENV_FILE" >/dev/null 2>&1
  }

  _ssh_agent_parse_key_file() {
    local key_file="$1"
    local line trimmed
    [[ -r "$key_file" ]] || return 0

    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%#*}"
      line="${line#"${line%%[![:space:]]*}"}"
      trimmed="${line%"${line##*[![:space:]]}"}"
      [[ -n "$trimmed" ]] || continue
      _ssh_agent_keys+=("${~trimmed}")
    done < "$key_file"
  }

  _ssh_agent_auto_add_keys() {
    local rc
    local key_file_default="$HOME/.ssh/agent-keys"
    local key_file_host="$HOME/.ssh/agent-keys.${SSH_AGENT_HOSTNAME}"
    local -a _ssh_agent_keys
    _ssh_agent_keys=()

    ssh-add -l >/dev/null 2>&1
    rc="$?"
    [[ "$rc" -eq 1 ]] || return 0

    if [[ -n "${SSH_AGENT_AUTO_KEYS:-}" ]]; then
      _ssh_agent_keys=("${(@Q)${(z)SSH_AGENT_AUTO_KEYS}}")
    else
      [[ -r "$key_file_default" ]] && _ssh_agent_parse_key_file "$key_file_default"
      [[ -r "$key_file_host" ]] && _ssh_agent_parse_key_file "$key_file_host"
    fi

    (( ${#_ssh_agent_keys[@]} > 0 )) || return 0
    ssh-add "${_ssh_agent_keys[@]}" </dev/null
  }

  _ssh_agent_load_env
  _ssh_agent_check || _ssh_agent_start
  _ssh_agent_auto_add_keys

  unset -f _ssh_agent_load_env _ssh_agent_check _ssh_agent_start _ssh_agent_parse_key_file _ssh_agent_auto_add_keys
  unset _ssh_agent_keys
fi
