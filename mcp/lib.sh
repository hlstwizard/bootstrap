#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
RUN_DIR="${SCRIPT_DIR}/run"
LOG_DIR="${RUN_DIR}/logs"
ENV_FILE="${SCRIPT_DIR}/.env"
SERVERS_FILE_DEFAULT="${SCRIPT_DIR}/servers.conf"
SERVERS_FILE="${MCP_SERVERS_FILE:-${SERVERS_FILE_DEFAULT}}"
MCP_ENDPOINT_HOST="${MCP_ENDPOINT_HOST:-127.0.0.1}"

ensure_runtime_dirs() {
	mkdir -p "${RUN_DIR}" "${LOG_DIR}"
}

load_env_file() {
	if [[ -f "${ENV_FILE}" ]]; then
		set -a
		# shellcheck source=/dev/null
		source "${ENV_FILE}"
		set +a
	fi
}

require_servers_file() {
	if [[ ! -f "${SERVERS_FILE}" ]]; then
		echo "error: MCP servers config not found: ${SERVERS_FILE}" >&2
		exit 2
	fi
}

read_servers() {
	require_servers_file

	while IFS='|' read -r name enabled port stdio_command; do
		if [[ -z "${name}" || "${name}" == \#* ]]; then
			continue
		fi

		if [[ -z "${enabled}" || -z "${port}" || -z "${stdio_command}" ]]; then
			echo "warn: invalid server config line in ${SERVERS_FILE}: ${name}|${enabled}|${port}|..." >&2
			continue
		fi

		printf '%s|%s|%s|%s\n' "${name}" "${enabled}" "${port}" "${stdio_command}"
	done <"${SERVERS_FILE}"
}

expand_command() {
	local raw="$1"
	set +u
	eval "printf '%s' \"${raw}\""
	set -u
}

mcp_url() {
	local port="$1"
	printf 'http://%s:%s/mcp' "${MCP_ENDPOINT_HOST}" "${port}"
}
