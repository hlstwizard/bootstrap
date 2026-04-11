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

`./bootstrap.sh` also installs `qmd` globally via npm (`npm install -g @tobilu/qmd`) after Brewfile packages are installed.

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

`zsh/.zshrc` also initializes Homebrew shell environment for both macOS and Linux
(`brew shellenv`), so custom scripts can safely use commands installed via Homebrew.
It also prepends `~/.local/bin` to `PATH` (when present), so user-installed CLI tools
such as `uv tool` shims are discoverable by default.

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

`zsh/scripts/ssh-agent.zsh` is also loaded automatically and will:

- reuse an existing `ssh-agent` from `${XDG_STATE_HOME:-~/.local/state}/ssh-agent/agent-<host>.env` when available
- start a new `ssh-agent` automatically when needed
- auto-add keys only when the agent has no identities

Per-host key customization (recommended):

- `~/.ssh/agent-keys`: shared key list for all hosts
- `~/.ssh/agent-keys.<hostname>`: host-specific key list (hostname defaults to `${HOST%%.*}`)

Each file supports one key path per line and `#` comments. Example:

```text
~/.ssh/id_ed25519
~/.ssh/work
# optional per-machine key
~/.ssh/personal
```

Optional env overrides:

- `SSH_AGENT_HOSTNAME`: override host tag used in env/key file names
- `SSH_AGENT_ENV_FILE`: override agent env file path
- `SSH_AGENT_AUTO_KEYS`: explicit key list string (shell words)

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

3. Initialize local Rime config from this repo:

```bash
./init.sh rime
```

This command will:

- symlink files from `Rime/` to `~/Library/Rime/` (including `custom_phrase_double.txt`, excluding `installation.yaml` and `user.yaml`)
- write `~/Library/Rime/installation.yaml` with:
  - a per-machine `installation_id` (default: `<os>-YYYYmmdd-HHMMSS`, e.g. `macos-20260408-141530`)
  - `sync_dir` defaults to `~/OneDrive*/RimeSync` (requires a OneDrive link under `$HOME` and existing `RimeSync`)
- create `${sync_dir}/${installation_id}` if missing

Validation behavior:

- if `~/OneDrive*` is missing, `./init.sh rime` exits with error
- if `~/OneDrive*/RimeSync` is missing, `./init.sh rime` exits with error
- use `RIME_SYNC_DIR` to override explicitly when needed

Optional overrides:

```bash
RIME_INSTALLATION_ID="mac-your-id" RIME_SYNC_DIR="$HOME/Library/CloudStorage/OneDrive-个人/RimeSync" ./init.sh rime
```

## Windows Initialization (PowerShell)

For Windows, use the PowerShell variant:

```powershell
.\init.ps1 <app>
```

Behavior mirrors the generic link flow of `init.sh` (with Windows-native config location):

- links `<repo>/<app>/` -> `%APPDATA%/<app>`
- `copilot` links to `~/.copilot`
- `ssh` links to `~/.ssh`
- `opencode` links to `~/.config/opencode`
- `wezterm` links config dir to `~/.config/wezterm` and ensures `~/.wezterm.lua` points to that config
- `git` links `git/.gitconfig` and `git/.gitignore_global` to home

Notes:

- If destination already exists and is not the desired symlink, it is moved to a timestamped backup first.
- `zsh` and `rime` are intentionally not supported in `init.ps1`; use `init.sh` for those app types.

4. Reload Rime: click the Squirrel menu bar icon -> **Deploy** (重新部署).

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
- **OpenCode (daemonized MCP mode)** reads it via `mcp/.env` when you run `mcp/mcp.sh start`.

### Env Templates (Recommended)

This repo provides env templates so you can keep a reusable setup across machines.

Sync templates to your home directory:

```bash
./init.sh env
```

This command copies:

- `env/templates/.local/bin/env` -> `~/.local/bin/env`
- `env/templates/.config/env.d/*.sh` -> `${XDG_CONFIG_HOME:-~/.config}/env.d/*.sh`

If destination files already exist and differ, they are moved to timestamped backups (`.bak.<timestamp>`) before copying.

Default behavior is **on-demand loading**:

- `source ~/.local/bin/env` to load helper functions
- `envlist` to list available modules
- `envload 20-app-opencode` to load a single module

Optional auto-load (selected modules only):

```bash
export ENV_AUTO_MODULES="20-app-opencode 20-app-mcp"
source ~/.local/bin/env
```

For per-machine differences, prefer setting `ENV_AUTO_MODULES` in `~/.zshrc.local` (not tracked in this repo):

```bash
# ~/.zshrc.local
export ENV_AUTO_MODULES="20-app-opencode"
```

`zsh/.zshrc` already loads `~/.zshrc.local` before `~/.local/bin/env`, so each machine can enable a different module set.

Included templates:

- `20-app-opencode.sh`: OpenCode-related non-secret env vars
- `20-app-mcp.sh`: local MCP host defaults (`MCP_ENDPOINT_HOST`)

Template naming convention:

- `00-*.sh`: base/shared settings
- `10-*.sh`: toolchain/path settings
- `20-app-*.sh`: app-specific settings (e.g. `20-app-opencode.sh`)
- `90-*.sh`: machine-local overrides

For secrets, do not store plaintext in env templates. Prefer Bitwarden (`~/.bw-env` + `bwenv`/`bwup`).

## Local Daemonized MCP Servers (Shared Across OpenCode Processes)

To avoid each OpenCode process spawning its own MCP server instances, this repo now supports shared local MCP daemons under `mcp/`.

Files:

- `mcp/mcp.sh`: manages MCP daemons with subcommands (`start|stop|status|restart`).
- `mcp/servers.conf`: server list and start commands (`name|enabled|port|stdio_command`).
- `mcp/lib.sh`: shared helper functions used by the scripts.
- `mcp/sync-opencode-mcp.sh`: syncs enabled server endpoints into `opencode/opencode.json`.

Current local endpoints (used by `opencode/opencode.json`):

- Azure MCP: `http://{env:MCP_ENDPOINT_HOST}:8781/mcp`
- awesome-copilot MCP: `http://{env:MCP_ENDPOINT_HOST}:8782/mcp`
- Context7 MCP: `http://{env:MCP_ENDPOINT_HOST}:8783/mcp`

You can override the endpoint host with `MCP_ENDPOINT_HOST` (for example your host LAN IP), so VMs can reach the MCP daemons.

### Usage

1. Create an env file for MCP-only secrets:

```bash
cp mcp/.env.example mcp/.env
```

2. Edit `mcp/.env` and set:

```text
CONTEXT7_API_KEY=your-api-key
# Optional: host/IP for generated endpoint URLs.
# Keep 127.0.0.1 for local-only access.
# Set this to your host LAN IP when OpenCode runs inside a VM.
MCP_ENDPOINT_HOST=127.0.0.1
```

3. Edit `mcp/servers.conf` if you need to customize ports, enable/disable servers, or replace commands:

```text
# name|enabled|port|stdio_command
azure|1|8781|uvx --from msmcp-azure azmcp server start
awesome-copilot|1|8782|docker run -i --rm ghcr.io/microsoft/mcp-dotnet-samples/awesome-copilot:latest
context7|1|8783|npx -y @upstash/context7-mcp --api-key ${CONTEXT7_API_KEY}
```

- Set `enabled` to `0` to disable a server.
- If you change ports, update `opencode/opencode.json` URLs accordingly.

4. Sync OpenCode MCP endpoints from `servers.conf`:

```bash
bash mcp/sync-opencode-mcp.sh
```

- This writes `opencode/opencode.json` `mcp` entries as `remote` URLs for enabled servers.
- By default, host is written as `{env:MCP_ENDPOINT_HOST}` so one linked config can be reused across different hosts.
- Override with a fixed literal host by setting `OPENCODE_MCP_ENDPOINT_HOST` when syncing.

5. Start daemons:

```bash
bash mcp/mcp.sh start
```

6. Check status:

```bash
bash mcp/mcp.sh status
```

7. Stop daemons when needed:

```bash
bash mcp/mcp.sh stop
```

8. Restart daemons when needed:

```bash
bash mcp/mcp.sh restart
```

Notes:

- Runtime files are stored in `mcp/run/` (`*.pid`, `logs/*.log`) and ignored by git.
- This keeps shell env loading on-demand: MCP-related env vars are only loaded when starting MCP daemons.
- You can override the servers config path with `MCP_SERVERS_FILE`, for example:

```bash
MCP_SERVERS_FILE=mcp/servers.conf.example bash mcp/mcp.sh status
```

- For VM access, set `MCP_ENDPOINT_HOST` to a reachable host IP (for example `192.168.x.x`) before running `mcp/sync-opencode-mcp.sh`.
- Ensure your VM networking mode and host firewall allow inbound access to MCP ports (`8781-8783` by default).

Example with fixed host at sync time:

```bash
OPENCODE_MCP_ENDPOINT_HOST=127.0.0.1 bash mcp/sync-opencode-mcp.sh
```

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
- Auto-load is disabled by default (`BW_ENV_AUTOLOAD=0`)
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

### AstroNvim (Neovim)

AstroNvim config lives in `nvim/` and is linked as your Neovim config:

```bash
./init.sh nvim
```

This creates a symlink from `nvim/` to `${XDG_CONFIG_HOME:-~/.config}/nvim`.

Plugin versions are locked in `nvim/lazy-lock.json` and should be committed to keep plugin behavior consistent across machines.

## TODO

- Add startup management integration (e.g., `launchd` on macOS) for MCP daemons if auto-start on login is desired.
