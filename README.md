# Bootstrap

## Install Applications

- Install brew from https://brew.sh/
- Install the applications from brew using the brewfile:

```bash
brew bundle --file=Brewfile
```

## Set Up Zsh

1. Install [Oh My Zsh](https://ohmyz.sh/):

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

2. Install plugins:

```bash
./install-zsh-plugins.sh
```

3. Enable the plugins in `~/.zshrc` by updating the `plugins` line:

```zsh
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
```

4. Load custom aliases by symlinking the `zsh/` config directory and sourcing it in `~/.zshrc`:

```bash
./init.sh zsh
```

```zsh
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/aliases.zsh"
```

## Configure Applications 

This repository mirrors ~/.config/ and can be reused across different machines.

Link an app directory from this repo into your host's config directory:

```bash
./init.sh opencode
```

This creates a symlink from `<repo>/opencode/` to `${XDG_CONFIG_HOME:-~/.config}/opencode`. If the destination already exists and isn't the desired symlink, it is moved aside to `*.bak.<timestamp>`.

Example: OpenCode

OpenCode configuration lives in `opencode/`.

- `opencode/AGENTS.md`: default agent instructions (copied from `~/AGENTS.md`).
