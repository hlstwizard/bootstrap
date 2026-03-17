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
If the destination already exists and is not the desired symlink, it will be
moved aside to a timestamped .bak.<timestamp> path.
EOF
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

src_abs="$(readlink -f "$src" 2>/dev/null || realpath "$src")"

if [[ -L "$dest" ]]; then
  dest_abs="$(readlink -f "$dest" 2>/dev/null || realpath "$dest")"
  if [[ "$dest_abs" == "$src_abs" ]]; then
    echo "ok: already linked: $dest -> $src_abs"
    exit 0
  fi
fi

if [[ -e "$dest" || -L "$dest" ]]; then
  ts="$(date +%Y%m%d%H%M%S)"
  backup="${dest}.bak.${ts}"
  mv -- "$dest" "$backup"
  echo "moved aside: $dest -> $backup"
fi

ln -s -- "$src_abs" "$dest"
echo "linked: $dest -> $src_abs"
