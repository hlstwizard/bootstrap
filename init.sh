#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
Usage: init.sh <app>

Example:
  ./init.sh opencode

This creates a symlink from this repo's <app>/ to $XDG_CONFIG_HOME/<app>
(or ~/.config/<app> if XDG_CONFIG_HOME is not set).
Exceptions:
  - for 'copilot', the link target is ~/.copilot
  - for 'ssh', the link target is ~/.ssh
  - for 'git', symlink git/.gitconfig -> ~/.gitconfig and
    git/.gitignore_global -> ~/.gitignore_global
If the destination already exists and is not the desired symlink, it will be
moved aside to a timestamped .bak.<timestamp> path.
EOF
}

link_path() {
	local src_path="$1"
	local dest_path="$2"
	local src_abs dest_abs ts backup

	src_abs="$(readlink -f "$src_path" 2>/dev/null || realpath "$src_path")"
	mkdir -p "$(dirname "$dest_path")"

	if [[ -L "$dest_path" ]]; then
		dest_abs="$(readlink -f "$dest_path" 2>/dev/null || realpath "$dest_path")"
		if [[ "$dest_abs" == "$src_abs" ]]; then
			echo "ok: already linked: $dest_path -> $src_abs"
			return 0
		fi
	fi

	if [[ -e "$dest_path" || -L "$dest_path" ]]; then
		ts="$(date +%Y%m%d%H%M%S)"
		backup="${dest_path}.bak.${ts}"
		mv -- "$dest_path" "$backup"
		echo "moved aside: $dest_path -> $backup"
	fi

	ln -s -- "$src_abs" "$dest_path"
	echo "linked: $dest_path -> $src_abs"
}

if [[ ${1-} == "-h" || ${1-} == "--help" ]]; then
	usage
	exit 0
elif [[ $# -eq 0 || ${1-} == "" ]]; then
	usage
	exit 1
fi

app="$1"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ "$app" == "git" ]]; then
	gitconfig_src="${script_dir}/git/.gitconfig"
	gitignore_src="${script_dir}/git/.gitignore_global"

	if [[ ! -f "$gitconfig_src" || ! -f "$gitignore_src" ]]; then
		echo "error: git config files not found under: ${script_dir}/git" >&2
		exit 2
	fi

	link_path "$gitconfig_src" "$HOME/.gitconfig"
	link_path "$gitignore_src" "$HOME/.gitignore_global"
	exit 0
fi

src="${script_dir}/${app}"

if [[ ! -d "$src" ]]; then
	echo "error: app '$app' not found at: $src" >&2
	exit 2
fi

if [[ "$app" == "copilot" ]]; then
	dest="$HOME/.copilot"
elif [[ "$app" == "ssh" ]]; then
	dest="$HOME/.ssh"
else
	config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
	dest="${config_home}/${app}"
	mkdir -p "$config_home"
fi

link_path "$src" "$dest"
