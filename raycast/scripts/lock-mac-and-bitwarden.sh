#!/bin/zsh

# @raycast.schemaVersion 1
# @raycast.title Lock Mac + Bitwarden
# @raycast.mode compact
# @raycast.packageName Security
# @raycast.icon 🔒
# @raycast.description Lock Bitwarden and then lock this Mac

set -euo pipefail

SESSION_CACHE_FILE="${HOME}/Library/Caches/raycast-bitwarden-session"
CGSESSION_BIN="/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"

if command -v bw >/dev/null 2>&1; then
	bw lock >/dev/null 2>&1 || true
fi

rm -f "$SESSION_CACHE_FILE"

if [[ -x "$CGSESSION_BIN" ]]; then
	"$CGSESSION_BIN" -suspend
else
	/usr/bin/pmset displaysleepnow
fi
