# config

My personal Linux configuration files following the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/).

This repository mirrors `~/.config/` and can be reused across different machines.

## Apps included

| App | Config path |
|-----|-------------|
| Git | `git/config` |
| Neovim | `nvim/init.lua` |
| Fish shell | `fish/config.fish` |
| Alacritty | `alacritty/alacritty.toml` |
| Starship prompt | `starship.toml` |

## Setup

Clone this repo and run the install script to create symlinks from `~/.config/` to the files in this repo:

```bash
git clone https://github.com/hlstwizard/config.git ~/.config
```

Or if `~/.config` already exists with other configs, create individual symlinks:

```bash
git clone https://github.com/hlstwizard/config.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

The `install.sh` script will back up any existing files before creating symlinks.

## Updating

After editing config files, commit and push normally with git. Pull changes on other machines with `git pull`.
