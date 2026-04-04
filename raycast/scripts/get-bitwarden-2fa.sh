#!/bin/zsh

# @raycast.schemaVersion 1
# @raycast.title Get Bitwarden 2FA Code
# @raycast.mode compact
# @raycast.packageName Security
# @raycast.icon 🔑
# @raycast.description Fetch TOTP code from Bitwarden CLI
# @raycast.argument1 { "type": "text", "placeholder": "Item name or ID" }

set -euo pipefail

ITEM="${1:-}"
SESSION_CACHE_FILE="${HOME}/Library/Caches/raycast-bitwarden-session"

if [[ -z "$ITEM" ]]; then
	echo "Please provide a Bitwarden item name or ID."
	exit 1
fi

if ! command -v bw >/dev/null 2>&1; then
	echo "Bitwarden CLI (bw) is not installed or not in PATH."
	exit 1
fi

get_status() {
	bw status --raw 2>/dev/null || echo '{"status":"unknown"}'
}

read_cached_session() {
	if [[ -f "$SESSION_CACHE_FILE" ]]; then
		tr -d '[:space:]' <"$SESSION_CACHE_FILE"
	fi
}

write_cached_session() {
	local session="$1"
	mkdir -p "$(dirname "$SESSION_CACHE_FILE")"
	printf '%s' "$session" >"$SESSION_CACHE_FILE"
	chmod 600 "$SESSION_CACHE_FILE"
}

clear_cached_session() {
	rm -f "$SESSION_CACHE_FILE"
}

prompt_master_password() {
	osascript <<'APPLESCRIPT'
set d to display dialog "Bitwarden vault is locked. Enter your master password:" default answer "" with title "Bitwarden Unlock" with hidden answer buttons {"Cancel", "Unlock"} default button "Unlock"
text returned of d
APPLESCRIPT
}

STATUS_JSON="$(get_status)"
STATUS="$(printf '%s' "$STATUS_JSON" | jq -r '.status // "unknown"')"

if [[ "$STATUS" == "unauthenticated" ]]; then
	echo "Bitwarden is not logged in. Run 'bw login' first."
	exit 1
fi

get_totp() {
	local item="$1"
	local session="${2:-}"

	if [[ -n "$session" ]]; then
		bw get totp "$item" --session "$session" 2>/dev/null || true
	else
		bw get totp "$item" 2>/dev/null || true
	fi
}

CODE=""

if [[ -n "${BW_SESSION:-}" ]]; then
	CODE="$(get_totp "$ITEM" "$BW_SESSION")"
fi

if [[ -z "$CODE" ]]; then
	CACHED_SESSION="$(read_cached_session || true)"
	if [[ -n "$CACHED_SESSION" ]]; then
		CODE="$(get_totp "$ITEM" "$CACHED_SESSION")"
		if [[ -z "$CODE" ]]; then
			clear_cached_session
		fi
	fi
fi

if [[ -z "$CODE" && "$STATUS" != "locked" ]]; then
	CODE="$(get_totp "$ITEM")"
fi

if [[ -z "$CODE" && "$STATUS" == "locked" ]]; then
	if ! command -v osascript >/dev/null 2>&1; then
		echo "osascript is required to prompt for master password."
		exit 1
	fi

	MASTER_PASSWORD="$(prompt_master_password 2>/dev/null || true)"

	if [[ -z "$MASTER_PASSWORD" ]]; then
		echo "Unlock cancelled."
		exit 1
	fi

	export BW_PASSWORD="$MASTER_PASSWORD"
	SESSION_KEY="$(bw unlock --raw --passwordenv BW_PASSWORD 2>/dev/null || true)"
	unset BW_PASSWORD
	unset MASTER_PASSWORD

	if [[ -z "$SESSION_KEY" ]]; then
		echo "Failed to unlock Bitwarden. Check your master password."
		exit 1
	fi

	write_cached_session "$SESSION_KEY"

	CODE="$(get_totp "$ITEM" "$SESSION_KEY")"
fi

if [[ -z "$CODE" ]]; then
	echo "Failed to fetch TOTP code for '$ITEM'. Ensure the item exists and has a TOTP secret."
	exit 1
fi

printf '%s' "$CODE" | pbcopy
echo "Copied 2FA code for '$ITEM': $CODE"
