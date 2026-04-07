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
Special behavior for 'zsh':
  - ensures Oh My Zsh is installed (unattended)
  - clones common custom plugins under $ZSH_CUSTOM/plugins
  - symlinks repo zsh/scripts/*.zsh into $ZSH_CUSTOM/*.zsh
  - symlinks repo zsh/.zshrc to ~/.zshrc
Special behavior for 'env':
  - copies template env loader to ~/.local/bin/env
  - copies env modules from env/templates/.config/env.d/*.sh to
    ${XDG_CONFIG_HOME:-~/.config}/env.d/
If the destination already exists and is not the desired symlink, it will be
moved aside to a timestamped .bak.<timestamp> path.
EOF
}

init_colors() {
	if [[ -t 1 && -z "${NO_COLOR-}" && "${TERM-}" != "dumb" ]]; then
		COLOR_OK="\033[32m"
		COLOR_WARN="\033[33m"
		COLOR_RESET="\033[0m"
	else
		COLOR_OK=""
		COLOR_WARN=""
		COLOR_RESET=""
	fi
}

log_ok() {
	printf "%b%s%b\n" "$COLOR_OK" "$1" "$COLOR_RESET"
}

log_warn() {
	printf "%b%s%b\n" "$COLOR_WARN" "$1" "$COLOR_RESET" >&2
}

link_path() {
	local src_path="$1"
	local dest_path="$2"
	local src_abs dest_abs ts backup

	src_abs="$(readlink -f "$src_path" 2>/dev/null || realpath "$src_path")"
	mkdir -p "$(dirname "$dest_path")"

	if [[ -L "$dest_path" ]]; then
		dest_abs="$(readlink -f "$dest_path" 2>/dev/null || realpath "$dest_path" 2>/dev/null || true)"
		if [[ "$dest_abs" == "$src_abs" ]]; then
			log_ok "ok: already linked: $dest_path -> $src_abs"
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

check_git_delta_installed() {
	if command -v delta >/dev/null 2>&1; then
		log_ok "ok: git-delta is installed"
		return 0
	fi

	log_warn "warn: git-delta is not installed"
	echo "hint: install it with: brew install git-delta" >&2
}

init_colors

if [[ ${1-} == "-h" || ${1-} == "--help" ]]; then
	usage
	exit 0
elif [[ $# -eq 0 || ${1-} == "" ]]; then
	usage
	exit 1
fi

app="$1"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

zsh_init_script="${script_dir}/zsh/init.sh"
if [[ -f "$zsh_init_script" ]]; then
	# shellcheck source=/dev/null
	source "$zsh_init_script"
fi

env_init_script="${script_dir}/env/init.sh"
if [[ -f "$env_init_script" ]]; then
	# shellcheck source=/dev/null
	source "$env_init_script"
fi

if [[ "$app" == "zsh" ]]; then
	if [[ ! -f "$zsh_init_script" ]]; then
		echo "error: zsh init script not found at: $zsh_init_script" >&2
		exit 2
	fi
	bootstrap_zsh "$script_dir"
	exit 0
fi

if [[ "$app" == "env" ]]; then
	if [[ ! -f "$env_init_script" ]]; then
		echo "error: env init script not found at: $env_init_script" >&2
		exit 2
	fi
	bootstrap_env "$script_dir"
	exit 0
fi

if [[ "$app" == "git" ]]; then
	gitconfig_src="${script_dir}/git/.gitconfig"
	gitignore_src="${script_dir}/git/.gitignore_global"

	if [[ ! -f "$gitconfig_src" || ! -f "$gitignore_src" ]]; then
		echo "error: git config files not found under: ${script_dir}/git" >&2
		exit 2
	fi

	link_path "$gitconfig_src" "$HOME/.gitconfig"
	link_path "$gitignore_src" "$HOME/.gitignore_global"
	check_git_delta_installed
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
