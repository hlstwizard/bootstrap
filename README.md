# Bootstrap

## Install Applications

- Install brew from https://brew.sh/
- Install the applications from brew using the brewfiles:

```bash
brew bundle --file=brewfiles/common.Brewfile
brew bundle --file=brewfiles/macos.Brewfile
brew bundle --file=brewfiles/ai.Brewfile
```

Or use the helper script to auto-select by OS:

```bash
./bootstrap.sh
```

- macOS (`Darwin`) -> `brewfiles/macos.Brewfile`
- Fedora Linux -> `brewfiles/fedora-dev.Brewfile`
- `brewfiles/common.Brewfile` is always applied first
- `brewfiles/ai.Brewfile` is applied last

- For a Fedora workstation (pure development profile), use:
  (manual alternative to `./bootstrap.sh`)

```bash
brew bundle --file=brewfiles/common.Brewfile
brew bundle --file=brewfiles/fedora-dev.Brewfile
brew bundle --file=brewfiles/ai.Brewfile
```

Design notes:

- Put shared tools in `brewfiles/common.Brewfile` (e.g., `fzf`).
- Put OS-specific tools in profile files (`brewfiles/macos.Brewfile` for macOS, `brewfiles/fedora-dev.Brewfile` for Fedora).
- Put AI tooling in `brewfiles/ai.Brewfile` (currently `anomalyco/tap/opencode`).
- If you want to replace a shared package later, update only `brewfiles/common.Brewfile`.

Notes:

- System utilities are managed in `brewfiles/macos.Brewfile` (currently `stats`, `hiddenbar`, and `raycast`).
- `raycast` is used as the launcher/window-management tool.
- Raycast config is stored in OneDrive; remember to back it up regularly.

### Raycast Security Scripts

This repo includes custom Raycast scripts under `raycast/scripts/`.

- `get-bitwarden-2fa.sh`: fetches TOTP from Bitwarden CLI and copies it to clipboard. It caches a BW session token in `~/Library/Caches/raycast-bitwarden-session` to reduce repeated unlock prompts.
- `lock-mac-and-bitwarden.sh`: locks Bitwarden first (`bw lock`), clears the cached session token file, then locks the Mac session.

Recommended hardening:

- In Raycast, bind your lock shortcut (for example `cmd+l`) to `lock-mac-and-bitwarden.sh` instead of the built-in Lock command.
- Keep the old lock command unbound to avoid bypassing Bitwarden lock.

## Set Up Zsh

1. Load zsh configs and plugins via:

```bash
./init.sh zsh
```

Implementation note: zsh bootstrap logic is maintained in `zsh/init.sh`, and `init.sh` only dispatches to it for the `zsh` app.

`./init.sh zsh` now:

- installs Oh My Zsh if missing (unattended)
- clones custom plugins listed in `zsh/plugins.conf` into `${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins`
- syncs plugin activation list to `~/.zsh_plugins`
- symlinks all repo `zsh/scripts/*.zsh` files into `${ZSH_CUSTOM:-~/.oh-my-zsh/custom}`
- symlinks repo `zsh/.zshrc` to `~/.zshrc`

To add a plugin, update only `zsh/plugins.conf` with one line per plugin:

```text
plugin-name|https://github.com/org/repo.git
```

For Oh My Zsh built-in plugins (no separate git repo), keep the URL empty:

```text
git|
```

Then rerun:

```bash
./init.sh zsh
```

This also loads `zsh/scripts/bracketed-paste.zsh`, which enables `bracketed-paste-magic` to prevent pasted commands from showing raw control prefixes like `[200~`.

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

Some tools require environment variables to be set. Add them to your shell config (e.g., `~/.zshrc` or a `zsh/scripts/*.zsh` file):

| Variable | Used by | Purpose |
|---|---|---|
| `CONTEXT7_API_KEY` | Copilot, OpenCode | API key for the [Context7 MCP](https://context7.com/) server |

```zsh
export CONTEXT7_API_KEY="your-api-key"
```

- **Copilot** reads it via `copilot/mcp-config.json` (passed as an HTTP header to the Context7 MCP endpoint).
- **OpenCode** reads it via `opencode/opencode.json` (passed to `npx @upstash/context7-mcp`).

### Load Env Vars From Bitwarden CLI (zsh)

If you use Bitwarden CLI (`bw`) to store secrets, zsh can auto-load selected values into env vars during shell startup.

1. Ensure dependencies exist:

```bash
brew install bitwarden-cli jq
```

2. Add mappings to `~/.bw-env` (one per line):

```text
# ENV_VAR|item-id-or-name|source
OPENAI_API_KEY|my-openai-key|password
GITHUB_TOKEN|gh-pat|field:token
MY_USERNAME|some-login|username
```

Supported `source` values:

- `password` (default)
- `notes`
- `username`
- `totp`
- `field:<Custom Field Name>`

3. Unlock Bitwarden vault before starting zsh (or run `bwenv` after unlocking):

```bash
export BW_SESSION="$(bw unlock --raw)"
```

4. Run `./init.sh zsh` to sync scripts, then open a new shell.

Notes:

- Loader script: `zsh/scripts/bitwarden-env.zsh`
- Default config file path: `~/.bw-env` (override with `BW_ENV_FILE`)
- Auto-load is enabled by default (`BW_ENV_AUTOLOAD=1`)
- Manual reload command in shell: `bwenv`
- Convenience command for unlock + load: `bwup`

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

### Git Global Config

Manage global Git config and ignore rules from this repo:

```bash
./init.sh git
```

This creates the following symlinks:

- `git/.gitconfig` -> `~/.gitconfig`
- `git/.gitignore_global` -> `~/.gitignore_global`

Included defaults:

- enforce Unix line endings (`core.eol=lf`, `core.autocrlf=input`)
- global ignore file (`core.excludesfile=~/.gitignore_global`)
- common quality-of-life settings (`fetch.prune`, `rebase.autoStash`, `push.autoSetupRemote`, etc.)
- `git-delta` integration for paging and interactive diffs (`core.pager=delta`, `interactive.diffFilter=delta --color-only`)
- `merge.conflictStyle=zdiff3` for clearer conflict context

When you run `./init.sh git`, the script also checks whether `delta` is installed and prints a hint if missing (`brew install git-delta`).

Example: OpenCode

OpenCode configuration lives in `opencode/`.

- `opencode/AGENTS.md`: default agent instructions (copied from `~/AGENTS.md`).
