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
  - for 'nvim', initializes git submodule nvim/ first (if declared)
Special behavior for 'zsh':
  - ensures Oh My Zsh is installed (unattended)
  - clones common custom plugins under $ZSH_CUSTOM/plugins
  - symlinks repo zsh/scripts/*.zsh into $ZSH_CUSTOM/*.zsh
  - symlinks repo zsh/.zshrc to ~/.zshrc
Special behavior for 'env':
  - copies template env loader to ~/.local/bin/env
  - copies env modules from env/templates/.config/env.d/*.sh to
    ${XDG_CONFIG_HOME:-~/.config}/env.d/
Special behavior for 'rime' (macOS):
  - symlinks repo Rime/* into ~/Library/Rime/ (except installation.yaml and user.yaml)
  - writes ~/Library/Rime/installation.yaml with a per-machine installation_id
    and sync_dir (default: ~/Library/CloudStorage/OneDrive-Personal/RimeSync)
  - creates ${sync_dir}/${installation_id} if missing
Env overrides:
  - RIME_INSTALLATION_ID: fixed installation_id to write
  - RIME_SYNC_DIR: fixed sync_dir to write
    (if unset, requires ~/OneDrive*/RimeSync to exist)
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

ensure_submodule_ready() {
	local repo_dir="$1"
	local submodule_path="$2"
	local gitmodules_file="$repo_dir/.gitmodules"

	if [[ ! -f "$gitmodules_file" ]]; then
		return 0
	fi

	if ! awk -F'=' -v path="$submodule_path" '
		$1 ~ /^[[:space:]]*path[[:space:]]*$/ {
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
			if ($2 == path) found = 1
		}
		END { exit(found ? 0 : 1) }
	' "$gitmodules_file"; then
		return 0
	fi

	if ! command -v git >/dev/null 2>&1; then
		echo "error: git is required to initialize submodule '$submodule_path', but it was not found in PATH" >&2
		exit 2
	fi

	echo "syncing submodule: $submodule_path"
	if ! git -C "$repo_dir" submodule update --init --recursive -- "$submodule_path"; then
		echo "error: failed to initialize submodule '$submodule_path'" >&2
		exit 2
	fi
}

extract_installation_id() {
	local file_path="$1"

	if [[ ! -f "$file_path" ]]; then
		return 0
	fi

	awk -F': ' '/^installation_id:/ {gsub(/"/, "", $2); print $2; exit}' "$file_path"
}

resolve_home_onedrive_sync_dir() {
	local onedrive_home=""
	local sync_dir=""
	local -a onedrive_candidates=()

	shopt -s nullglob
	onedrive_candidates=("$HOME"/OneDrive*)
	shopt -u nullglob

	if [[ ${#onedrive_candidates[@]} -eq 0 ]]; then
		log_warn "error: no OneDrive link found under $HOME (expected ~/OneDrive*)"
		echo "hint: ensure OneDrive creates a link in home directory first" >&2
		return 1
	fi

	if [[ -e "$HOME/OneDrive" ]]; then
		onedrive_home="$HOME/OneDrive"
	else
		onedrive_home="${onedrive_candidates[0]}"
	fi

	sync_dir="$onedrive_home/RimeSync"
	if [[ ! -d "$sync_dir" ]]; then
		log_warn "error: RimeSync directory not found: $sync_dir"
		echo "hint: create it first, or set RIME_SYNC_DIR explicitly" >&2
		return 1
	fi

	printf '%s\n' "$sync_dir"
}

derive_timestamp_installation_id() {
	local os_raw os_slug

	os_raw="$(uname -s 2>/dev/null || true)"
	os_slug="$(printf '%s' "$os_raw" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-')"
	os_slug="${os_slug#-}"
	os_slug="${os_slug%-}"

	if [[ "$os_slug" == "darwin" ]]; then
		os_slug="macos"
	elif [[ -z "$os_slug" ]]; then
		os_slug="unknown-os"
	fi

	printf '%s-%s\n' "$os_slug" "$(date +%Y%m%d-%H%M%S)"
}

bootstrap_rime() {
	local script_dir="$1"
	local rime_src="$script_dir/Rime"
	local rime_src_legacy="$script_dir/Rime/mac_double_pinyin_fly"
	local rime_dest="$HOME/Library/Rime"
	local installation_file="$rime_dest/installation.yaml"
	local sync_dir_default=""
	local sync_dir=""
	local installation_id="${RIME_INSTALLATION_ID:-}"
	local existing_installation_id=""
	local src_file base_name ts backup

	if [[ ! -d "$rime_src" && -d "$rime_src_legacy" ]]; then
		rime_src="$rime_src_legacy"
	fi

	if [[ ! -d "$rime_src" ]]; then
		echo "error: rime source not found at: $rime_src" >&2
		exit 2
	fi

	if ! compgen -G "$rime_src/*" >/dev/null; then
		echo "error: rime source has no files: $rime_src" >&2
		exit 2
	fi

	if ! sync_dir_default="$(resolve_home_onedrive_sync_dir)"; then
		exit 2
	fi
	sync_dir="${RIME_SYNC_DIR:-$sync_dir_default}"

	mkdir -p "$rime_dest"

	for src_file in "$rime_src"/*; do
		base_name="$(basename "$src_file")"
		if [[ "$base_name" == "installation.yaml" || "$base_name" == "user.yaml" ]]; then
			continue
		fi
		link_path "$src_file" "$rime_dest/$base_name"
	done

	if [[ -z "$installation_id" ]]; then
		existing_installation_id="$(extract_installation_id "$installation_file")"
		if [[ -n "$existing_installation_id" && "$existing_installation_id" != "mac_double_pinyin_fly" ]]; then
			installation_id="$existing_installation_id"
		else
			installation_id="$(derive_timestamp_installation_id)"
		fi
	fi

	if [[ -e "$installation_file" || -L "$installation_file" ]]; then
		ts="$(date +%Y%m%d%H%M%S)"
		backup="${installation_file}.bak.${ts}"
		mv -- "$installation_file" "$backup"
		echo "moved aside: $installation_file -> $backup"
	fi

	mkdir -p "$sync_dir/$installation_id"

	cat >"$installation_file" <<EOF
distribution_code_name: Squirrel
distribution_name: "鼠鬚管"
distribution_version: 1.1.2
install_time: "$(date)"
installation_id: "$installation_id"
rime_version: 1.16.0
sync_dir: "$sync_dir"
EOF

	log_ok "ok: rime linked to $rime_dest"
	log_ok "ok: installation_id=$installation_id"
	log_ok "ok: sync_dir=$sync_dir"
	echo "next: deploy in Squirrel menu (重新部署)"
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

if [[ "$app" == "rime" ]]; then
	bootstrap_rime "$script_dir"
	exit 0
fi

if [[ "$app" == "nvim" ]]; then
	ensure_submodule_ready "$script_dir" "nvim"
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
