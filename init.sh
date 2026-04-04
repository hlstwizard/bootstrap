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
If the destination already exists and is not the desired symlink, it will be
moved aside to a timestamped .bak.<timestamp> path.
EOF
}

install_oh_my_zsh_if_missing() {
	if [[ -d "$HOME/.oh-my-zsh" ]]; then
		echo "ok: Oh My Zsh already installed"
		return 0
	fi

	echo "installing: Oh My Zsh (unattended)"
	RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

clone_plugin_if_missing() {
	local plugin_name="$1"
	local repo_url="$2"
	local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
	local plugin_dir="${plugins_dir}/${plugin_name}"

	mkdir -p "$plugins_dir"

	if [[ -d "$plugin_dir" ]]; then
		echo "ok: plugin already installed: $plugin_name"
		return 0
	fi

	echo "installing: plugin $plugin_name"
	git clone "$repo_url" "$plugin_dir"
}

install_zsh_plugins() {
	clone_plugin_if_missing "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
	clone_plugin_if_missing "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
	clone_plugin_if_missing "zsh-fzf-history-search" "https://github.com/joshskidmore/zsh-fzf-history-search.git"
}

link_zsh_custom_files() {
	local script_dir="$1"
	local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
	local src_file dest_file

	if [[ ! -d "${script_dir}/zsh/scripts" ]]; then
		echo "error: zsh scripts directory not found at: ${script_dir}/zsh/scripts" >&2
		exit 2
	fi

	mkdir -p "$zsh_custom"

	for src_file in "${script_dir}/zsh/scripts/"*.zsh; do
		if [[ ! -f "$src_file" ]]; then
			continue
		fi
		dest_file="${zsh_custom}/$(basename "$src_file")"
		link_path "$src_file" "$dest_file"
	done
}

link_zshrc_file() {
	local script_dir="$1"
	local zshrc_src="${script_dir}/zsh/.zshrc"

	if [[ ! -f "$zshrc_src" ]]; then
		echo "error: zshrc file not found at: $zshrc_src" >&2
		exit 2
	fi

	link_path "$zshrc_src" "$HOME/.zshrc"
}

bootstrap_zsh() {
	local script_dir="$1"
	install_oh_my_zsh_if_missing
	install_zsh_plugins
	link_zsh_custom_files "$script_dir"
	link_zshrc_file "$script_dir"
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

if [[ "$app" == "zsh" ]]; then
	bootstrap_zsh "$script_dir"
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
