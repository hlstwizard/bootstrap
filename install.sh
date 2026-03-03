#!/usr/bin/env bash
# install.sh — symlink config files into ~/.config/
# Run this script from the root of the cloned repo.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

backup_and_link() {
    local src="$1"
    local dst="$2"

    # Create parent directory if needed
    mkdir -p "$(dirname "$dst")"

    # Back up existing file/dir (not if it's already a symlink to our repo)
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        echo "Backing up $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi

    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        echo "Already linked: $dst"
    else
        ln -sf "$src" "$dst"
        echo "Linked: $dst -> $src"
    fi
}

# Symlink each top-level entry in the repo (excluding hidden files and this script)
shopt -s nullglob
for entry in "$REPO_DIR"/*/; do
    name="$(basename "$entry")"
    backup_and_link "$entry" "$CONFIG_DIR/$name"
done

# Symlink standalone config files at the repo root (e.g. starship.toml)
for file in "$REPO_DIR"/*.toml "$REPO_DIR"/*.ini "$REPO_DIR"/*.conf; do
    [[ -e "$file" ]] || continue
    name="$(basename "$file")"
    backup_and_link "$file" "$CONFIG_DIR/$name"
done

echo "Done. Config symlinks are set up in $CONFIG_DIR"
