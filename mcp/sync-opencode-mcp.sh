#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib.sh"

OPENCODE_CONFIG_FILE_DEFAULT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)/opencode/opencode.json"
OPENCODE_CONFIG_FILE="${OPENCODE_CONFIG_FILE:-${OPENCODE_CONFIG_FILE_DEFAULT}}"

load_env_file
require_servers_file

# Host value written into opencode/opencode.json MCP URLs.
# Default to OpenCode env-var substitution so one linked config can work across hosts.
# You can override with a literal host/IP, e.g. OPENCODE_MCP_ENDPOINT_HOST=127.0.0.1.
OPENCODE_MCP_ENDPOINT_HOST="${OPENCODE_MCP_ENDPOINT_HOST:-{env:MCP_ENDPOINT_HOST}}"

if [[ ! -f "${OPENCODE_CONFIG_FILE}" ]]; then
	echo "error: OpenCode config not found: ${OPENCODE_CONFIG_FILE}" >&2
	exit 2
fi

python3 - "${SERVERS_FILE}" "${OPENCODE_CONFIG_FILE}" "${OPENCODE_MCP_ENDPOINT_HOST}" <<'PY'
import json
import sys

servers_file = sys.argv[1]
opencode_file = sys.argv[2]
endpoint_host = sys.argv[3]

mcp = {}
with open(servers_file, "r", encoding="utf-8") as f:
    for lineno, raw in enumerate(f, start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue

        parts = line.split("|", 3)
        if len(parts) != 4:
            print(f"warn: invalid line {lineno} in {servers_file}: {line}", file=sys.stderr)
            continue

        name, enabled, port, _command = parts
        if enabled != "1":
            continue

        mcp[name] = {
            "type": "remote",
            "url": f"http://{endpoint_host}:{port}/mcp",
        }

with open(opencode_file, "r", encoding="utf-8") as f:
    cfg = json.load(f)

cfg["mcp"] = mcp

with open(opencode_file, "w", encoding="utf-8") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
PY

echo "synced: ${OPENCODE_CONFIG_FILE} mcp <- ${SERVERS_FILE} (host=${OPENCODE_MCP_ENDPOINT_HOST})"
