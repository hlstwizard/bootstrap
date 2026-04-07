#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib.sh"

print_usage() {
	cat <<'EOF'
Usage: bash mcp/mcp.sh <command>

Commands:
  start    Start all enabled MCP daemons
  stop     Stop all enabled MCP daemons
  status   Show daemon status
  restart  Restart all enabled MCP daemons
EOF
}

warn_context7_key_if_empty() {
	if [[ -z "${CONTEXT7_API_KEY-}" ]]; then
		echo "warn: CONTEXT7_API_KEY is empty. start may fail for servers requiring it." >&2
	fi
}

start_server() {
	local name="$1"
	local port="$2"
	local stdio_command="$3"
	local pid_file="${RUN_DIR}/${name}.pid"
	local log_file="${LOG_DIR}/${name}.log"

	if [[ -f "${pid_file}" ]]; then
		local existing_pid
		existing_pid="$(cat "${pid_file}")"
		if kill -0 "${existing_pid}" >/dev/null 2>&1; then
			echo "ok: ${name} already running (pid ${existing_pid}, port ${port})"
			return 0
		fi
		rm -f "${pid_file}"
	fi

	nohup npx -y supergateway \
		--stdio "${stdio_command}" \
		--outputTransport streamableHttp \
		--port "${port}" \
		--streamableHttpPath /mcp \
		--healthEndpoint /healthz \
		--logLevel info \
		>"${log_file}" 2>&1 &

	local pid=$!
	sleep 1
	if ! kill -0 "${pid}" >/dev/null 2>&1; then
		echo "error: failed to start ${name}. see ${log_file}" >&2
		exit 3
	fi

	echo "${pid}" >"${pid_file}"
	echo "started: ${name} pid=${pid} url=$(mcp_url "${port}")"
}

stop_server() {
	local name="$1"
	local pid_file="${RUN_DIR}/${name}.pid"

	if [[ ! -f "${pid_file}" ]]; then
		echo "skip: ${name} not running (no pid file)"
		return 0
	fi

	local pid
	pid="$(cat "${pid_file}")"
	if ! kill -0 "${pid}" >/dev/null 2>&1; then
		echo "skip: ${name} pid ${pid} already stopped"
		rm -f "${pid_file}"
		return 0
	fi

	kill "${pid}" >/dev/null 2>&1 || true
	sleep 1
	if kill -0 "${pid}" >/dev/null 2>&1; then
		kill -9 "${pid}" >/dev/null 2>&1 || true
	fi

	rm -f "${pid_file}"
	echo "stopped: ${name} pid=${pid}"
}

print_status() {
	local name="$1"
	local port="$2"
	local pid_file="${RUN_DIR}/${name}.pid"

	if [[ ! -f "${pid_file}" ]]; then
		echo "${name}: stopped"
		return 0
	fi

	local pid
	pid="$(cat "${pid_file}")"
	if kill -0 "${pid}" >/dev/null 2>&1; then
		echo "${name}: running (pid ${pid}) $(mcp_url "${port}")"
	else
		echo "${name}: stale pid file (${pid})"
	fi
}

do_start() {
	load_env_file
	warn_context7_key_if_empty

	while IFS='|' read -r name enabled port raw_command; do
		if [[ "${enabled}" != "1" ]]; then
			echo "skip: ${name} disabled"
			continue
		fi

		local resolved_command
		resolved_command="$(expand_command "${raw_command}")"
		start_server "${name}" "${port}" "${resolved_command}"
	done < <(read_servers)

	echo "all MCP daemons are up"
}

do_stop() {
	while IFS='|' read -r name enabled port raw_command; do
		if [[ "${enabled}" != "1" ]]; then
			echo "skip: ${name} disabled"
			continue
		fi
		stop_server "${name}"
	done < <(read_servers)
}

do_status() {
	load_env_file

	while IFS='|' read -r name enabled port raw_command; do
		if [[ "${enabled}" != "1" ]]; then
			echo "${name}: disabled"
			continue
		fi
		print_status "${name}" "${port}"
	done < <(read_servers)
}

main() {
	ensure_runtime_dirs

	local command="${1-}"
	case "${command}" in
	start)
		do_start
		;;
	stop)
		do_stop
		;;
	status)
		do_status
		;;
	restart)
		do_stop
		do_start
		;;
	-h | --help | help | "")
		print_usage
		;;
	*)
		echo "error: unknown command '${command}'" >&2
		print_usage >&2
		exit 1
		;;
	esac
}

main "$@"
