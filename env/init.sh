env_template_root() {
	local script_dir="$1"
	echo "${script_dir}/env/templates"
}

sync_template_file() {
	local src_path="$1"
	local dest_path="$2"
	local ts backup

	mkdir -p "$(dirname "$dest_path")"

	if [[ -f "$dest_path" ]] && cmp -s -- "$src_path" "$dest_path"; then
		log_ok "ok: already synced: $dest_path"
		return 0
	fi

	if [[ -e "$dest_path" || -L "$dest_path" ]]; then
		ts="$(date +%Y%m%d%H%M%S)"
		backup="${dest_path}.bak.${ts}"
		mv -- "$dest_path" "$backup"
		echo "moved aside: $dest_path -> $backup"
	fi

	cp -- "$src_path" "$dest_path"
	echo "synced: $dest_path <- $src_path"
}

bootstrap_env() {
	local script_dir="$1"
	local template_root env_src env_dest
	local config_home env_d_src env_d_dest src_file

	template_root="$(env_template_root "$script_dir")"
	env_src="${template_root}/.local/bin/env"
	env_dest="$HOME/.local/bin/env"

	if [[ ! -f "$env_src" ]]; then
		echo "error: env template file not found at: $env_src" >&2
		exit 2
	fi

	sync_template_file "$env_src" "$env_dest"
	chmod 700 "$env_dest"

	config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
	env_d_src="${template_root}/.config/env.d"
	env_d_dest="${config_home}/env.d"

	if [[ ! -d "$env_d_src" ]]; then
		echo "error: env template directory not found at: $env_d_src" >&2
		exit 2
	fi

	mkdir -p "$env_d_dest"

	for src_file in "$env_d_src"/*.sh; do
		if [[ ! -f "$src_file" ]]; then
			continue
		fi
		sync_template_file "$src_file" "${env_d_dest}/$(basename "$src_file")"
	done
}
