#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
brewfiles_dir="${script_dir}/brewfiles"

os="$(uname -s)"
case "$os" in
Darwin)
	profile_file="${brewfiles_dir}/macos.Brewfile"
	;;
Linux)
	if [[ -f /etc/os-release ]] && grep -qi '^ID=fedora$' /etc/os-release; then
		profile_file="${brewfiles_dir}/fedora-dev.Brewfile"
	else
		echo "error: unsupported Linux distribution. This script currently supports Fedora only." >&2
		echo "hint: run 'brew bundle --file=<path-to-brewfile>' manually." >&2
		exit 2
	fi
	;;
*)
	echo "error: unsupported OS: $os" >&2
	exit 2
	;;
esac

common_file="${brewfiles_dir}/common.Brewfile"

if [[ ! -f "$common_file" ]]; then
	echo "error: common brewfile not found: $common_file" >&2
	exit 3
fi

if [[ ! -f "$profile_file" ]]; then
	echo "error: profile brewfile not found: $profile_file" >&2
	exit 3
fi

echo "Using common Brewfile: $common_file"
brew bundle --file="$common_file"

echo "Using profile Brewfile: $profile_file"
brew bundle --file="$profile_file"
