# Bootstrap

## Install Applications

- Install brew from https://brew.sh/
- Install the applications from brew using the brewfiles:

```bash
brew bundle --file=brewfiles/common.Brewfile
brew bundle --file=brewfiles/macos.Brewfile
```

Or use the helper script to auto-select by OS:

```bash
./bootstrap.sh
```

- macOS (`Darwin`) -> `brewfiles/macos.Brewfile`
- Fedora Linux -> `brewfiles/fedora-dev.Brewfile`
- `brewfiles/common.Brewfile` is always applied first

- For a Fedora workstation (pure development profile), use:
  (manual alternative to `./bootstrap.sh`)

```bash
brew bundle --file=brewfiles/common.Brewfile
brew bundle --file=brewfiles/fedora-dev.Brewfile
```

Design notes:

- Put shared tools in `brewfiles/common.Brewfile` (e.g., `fzf`).
- Put OS-specific tools in profile files (`brewfiles/macos.Brewfile` for macOS, `brewfiles/fedora-dev.Brewfile` for Fedora).
- If you want to replace a shared package later, update only `brewfiles/common.Brewfile`.

Notes:

- System utilities are managed in `brewfiles/macos.Brewfile` (currently `stats`, `hiddenbar`, and `raycast`).
- `raycast` is used as the launcher/window-management tool.
- Raycast config is stored in OneDrive; remember to back it up regularly.

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

4. Load zsh configs by symlinking the `zsh/` config directory and sourcing all `*.zsh` files in `~/.zshrc`:

```bash
./init.sh zsh
```

```zsh
for f in "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/"*.zsh; do source "$f"; done
```

This also loads `zsh/bracketed-paste.zsh`, which enables `bracketed-paste-magic` to prevent pasted commands from showing raw control prefixes like `[200~`.

## Input Method (Rime / Squirrel)

1. Install [Squirrel](https://rime.im/) via Homebrew (included in `brewfiles/macos.Brewfile`) or manually.

2. Install [rime-ice](https://github.com/iDvel/rime-ice) (雾凇拼音) using [Plum](https://github.com/rime/plum) (东风破):

```bash
# Install Plum
cd ~
git clone https://github.com/rime/plum.git plum

# Install all rime-ice files
cd ~/plum
bash rime-install iDvel/rime-ice:others/recipes/full
```

> To update rime-ice later, re-run `bash rime-install iDvel/rime-ice:others/recipes/full` from `~/plum`.

3. Overlay your saved config from OneDrive on top of the rime-ice base:

```bash
cp -r ~/Library/CloudStorage/OneDrive-Personal/RimeSync/. ~/Library/Rime/
```

4. Reload Rime: click the Squirrel menu bar icon → **Deploy** (重新部署).

> The Rime config folder defaults to `~/Library/Rime` on macOS.

## Environment Variables

Some tools require environment variables to be set. Add them to your shell config (e.g., `~/.zshrc` or a `zsh/*.zsh` file):

| Variable | Used by | Purpose |
|---|---|---|
| `CONTEXT7_API_KEY` | Copilot, OpenCode | API key for the [Context7 MCP](https://context7.com/) server |

```zsh
export CONTEXT7_API_KEY="your-api-key"
```

- **Copilot** reads it via `copilot/mcp-config.json` (passed as an HTTP header to the Context7 MCP endpoint).
- **OpenCode** reads it via `opencode/opencode.json` (passed to `npx @upstash/context7-mcp`).

## Configure Applications 

This repository primarily mirrors `~/.config/` and can be reused across different machines.

Link an app directory from this repo into your host's config directory:

```bash
./init.sh opencode
```

By default, this creates a symlink from `<repo>/<app>/` to `${XDG_CONFIG_HOME:-~/.config}/<app>`.

Exceptions:

- `copilot` links to `~/.copilot`
- `ssh` links to `~/.ssh`

### SSH Config

SSH hosts are managed in `ssh/config` in this repository.

```bash
./init.sh ssh
```

This symlinks the repo `ssh/` directory to `~/.ssh` so host aliases (for example `testing` and `openclaw-test`) stay versioned and consistent across machines.

If the destination already exists and isn't the desired symlink, it is moved aside to `*.bak.<timestamp>`.

Example: OpenCode

OpenCode configuration lives in `opencode/`.

- `opencode/AGENTS.md`: default agent instructions (copied from `~/AGENTS.md`).
