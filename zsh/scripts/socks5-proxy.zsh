if [[ "$OSTYPE" == darwin* ]]; then
  typeset -g MAC_SOCKS5_PROXY_HOST="${MAC_SOCKS5_PROXY_HOST:-192.168.0.201}"
  typeset -g MAC_SOCKS5_PROXY_PORT="${MAC_SOCKS5_PROXY_PORT:-7893}"
  typeset -g MAC_SOCKS5_PROXY_DNS_SERVERS="${MAC_SOCKS5_PROXY_DNS_SERVERS-$MAC_SOCKS5_PROXY_HOST}"

  _mac_socks5_proxy_credential() {
    local key="$1"
    local value=""

    case "$key" in
      user)
        value="${MAC_SOCKS5_PROXY_USER:-${SOCKS5_PROXY_USER:-}}"
        ;;
      pass)
        value="${MAC_SOCKS5_PROXY_PASS:-${SOCKS5_PROXY_PASS:-}}"
        ;;
    esac

    printf '%s' "$value"
  }

  _mac_socks5_proxy_services() {
    local line service

    while IFS= read -r line; do
      [[ "$line" == "An asterisk (*) denotes that a network service is disabled." ]] && continue
      service="${line#\*}"
      service="${service#"${service%%[![:space:]]*}"}"
      [[ -n "$service" ]] && printf '%s\n' "$service"
    done < <(networksetup -listallnetworkservices 2>/dev/null)
  }

  _mac_socks5_proxy_wifi_service() {
    local configured_service="${MAC_SOCKS5_PROXY_SERVICE:-}"
    local service
    local -a services

    services=("${(@f)$(_mac_socks5_proxy_services)}")
    if (( ${#services[@]} == 0 )); then
      printf 's5proxy: no macOS network services found\n' >&2
      return 1
    fi

    if [[ -n "$configured_service" ]]; then
      for service in "${services[@]}"; do
        if [[ "$service" == "$configured_service" ]]; then
          printf '%s' "$service"
          return 0
        fi
      done
      printf 's5proxy: configured service not found: %s\n' "$configured_service" >&2
      return 1
    fi

    for service in "${services[@]}"; do
      if [[ "$service" == "Wi-Fi" ]]; then
        printf '%s' "$service"
        return 0
      fi
    done

    for service in "${services[@]}"; do
      if [[ "$service:l" == *"wi-fi"* || "$service:l" == *"wifi"* ]]; then
        printf '%s' "$service"
        return 0
      fi
    done

    printf 's5proxy: Wi-Fi service not found; set MAC_SOCKS5_PROXY_SERVICE explicitly\n' >&2
    return 1
  }

  _mac_socks5_proxy_dns_state_file() {
    local service="$1"
    local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/s5proxy"
    local service_tag="${service//[^[:alnum:]._-]/_}"

    mkdir -p "$state_dir" || return 1
    printf '%s/dns-%s.state' "$state_dir" "$service_tag"
  }

  _mac_socks5_proxy_dns_backup() {
    local service="$1"
    local state_file dns_output

    state_file="$(_mac_socks5_proxy_dns_state_file "$service")" || return 1
    if [[ -f "$state_file" ]]; then
      return 0
    fi

    dns_output="$(networksetup -getdnsservers "$service" 2>&1)" || return 1
    if [[ "$dns_output" == "There aren't any DNS Servers set on $service." ]]; then
      printf '__AUTO__\n' >| "$state_file"
      return 0
    fi

    printf '%s\n' "$dns_output" >| "$state_file"
  }

  _mac_socks5_proxy_dns_set() {
    local service="$1"
    local output rc
    local -a dns_servers

    [[ -n "$MAC_SOCKS5_PROXY_DNS_SERVERS" ]] || return 0

    dns_servers=("${(@z)MAC_SOCKS5_PROXY_DNS_SERVERS}")
    (( ${#dns_servers[@]} > 0 )) || return 0

    _mac_socks5_proxy_dns_backup "$service" || {
      printf 's5proxy: failed to backup current DNS for [%s]\n' "$service" >&2
      return 1
    }

    output="$(networksetup -setdnsservers "$service" "${dns_servers[@]}" 2>&1)"
    rc="$?"
    if (( rc != 0 )); then
      printf 's5proxy: failed to set DNS for [%s]: %s\n' "$service" "$output" >&2
      return "$rc"
    fi

    printf 's5proxy: DNS set for [%s]: %s\n' "$service" "$MAC_SOCKS5_PROXY_DNS_SERVERS"
    return 0
  }

  _mac_socks5_proxy_dns_restore() {
    local service="$1"
    local state_file output rc
    local -a dns_servers

    state_file="$(_mac_socks5_proxy_dns_state_file "$service")" || return 1
    [[ -f "$state_file" ]] || return 0

    dns_servers=("${(@f)$(<"$state_file")}")
    if (( ${#dns_servers[@]} == 0 )); then
      rm -f "$state_file"
      return 0
    fi

    if [[ "${dns_servers[1]}" == "__AUTO__" ]]; then
      output="$(networksetup -setdnsservers "$service" Empty 2>&1)"
      rc="$?"
      if (( rc != 0 )); then
        printf 's5proxy: failed to restore automatic DNS for [%s]: %s\n' "$service" "$output" >&2
        return "$rc"
      fi
      rm -f "$state_file"
      printf 's5proxy: DNS restored to automatic for [%s]\n' "$service"
      return 0
    fi

    output="$(networksetup -setdnsservers "$service" "${dns_servers[@]}" 2>&1)"
    rc="$?"
    if (( rc != 0 )); then
      printf 's5proxy: failed to restore DNS for [%s]: %s\n' "$service" "$output" >&2
      return "$rc"
    fi

    rm -f "$state_file"
    printf 's5proxy: DNS restored for [%s]\n' "$service"
    return 0
  }

  _mac_socks5_proxy_apply() {
    local action="$1"
    local user pass service
    local output
    local rc
    local warned_duplicate=0

    service="$(_mac_socks5_proxy_wifi_service)" || return $?

    if [[ "$action" == "on" ]]; then
      user="$(_mac_socks5_proxy_credential user)"
      pass="$(_mac_socks5_proxy_credential pass)"

      if [[ -z "$user" || -z "$pass" ]]; then
        printf 's5proxy: missing proxy credentials; set MAC_SOCKS5_PROXY_USER and MAC_SOCKS5_PROXY_PASS\n' >&2
        return 2
      fi

      output="$(networksetup -setsocksfirewallproxy "$service" "$MAC_SOCKS5_PROXY_HOST" "$MAC_SOCKS5_PROXY_PORT" on "$user" "$pass" 2>&1)"
      rc="$?"
      if (( rc != 0 )); then
        if [[ "$output" == *"error -25299"* ]]; then
          if (( warned_duplicate == 0 )); then
            printf 's5proxy: proxy credential already exists in Keychain, reusing it\n' >&2
            warned_duplicate=1
          fi
        else
          printf 's5proxy: failed to set SOCKS5 proxy for [%s]: %s\n' "$service" "$output" >&2
          return "$rc"
        fi
      fi

      output="$(networksetup -setsocksfirewallproxystate "$service" on 2>&1)"
      rc="$?"
      if (( rc != 0 )); then
        printf 's5proxy: failed to enable SOCKS5 proxy for [%s]: %s\n' "$service" "$output" >&2
        return "$rc"
      fi

      _mac_socks5_proxy_dns_set "$service" || return $?

      printf 's5proxy: enabled (%s:%s) for [%s]\n' "$MAC_SOCKS5_PROXY_HOST" "$MAC_SOCKS5_PROXY_PORT" "$service"
      return 0
    fi

    output="$(networksetup -setsocksfirewallproxystate "$service" off 2>&1)"
    rc="$?"
    if (( rc != 0 )); then
      printf 's5proxy: failed to disable SOCKS5 proxy for [%s]: %s\n' "$service" "$output" >&2
      return "$rc"
    fi

    _mac_socks5_proxy_dns_restore "$service" || return $?

    printf 's5proxy: disabled for [%s]\n' "$service"
  }

  _mac_socks5_proxy_status() {
    local service

    service="$(_mac_socks5_proxy_wifi_service)" || return $?
    printf '[%s]\n' "$service"
    networksetup -getsocksfirewallproxy "$service"
    printf '\n'
  }

  s5proxy() {
    local service

    if ! command -v networksetup >/dev/null 2>&1; then
      printf 's5proxy: networksetup command not found\n' >&2
      return 127
    fi

    case "${1:-status}" in
      on|enable)
        _mac_socks5_proxy_apply on
        ;;
      off|disable)
        _mac_socks5_proxy_apply off
        ;;
      status)
        _mac_socks5_proxy_status
        ;;
      dns-status)
        service="$(_mac_socks5_proxy_wifi_service)" || return $?
        printf '[%s]\n' "$service"
        networksetup -getdnsservers "$service"
        ;;
      *)
        printf 'Usage: s5proxy <on|off|status|dns-status>\n' >&2
        return 2
        ;;
    esac
  }

fi
