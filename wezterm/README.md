# WezTerm Notes

Use `show-keys` to verify the effective keybindings loaded from this config.

## Platform-specific commands

- macOS / Linux (from this repo root):

```bash
wezterm --config-file "./wezterm/wezterm.lua" show-keys
```

- macOS / Linux (after `./init.sh wezterm` symlink setup):

```bash
wezterm --config-file "${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/wezterm.lua" show-keys
```

- Windows PowerShell (after `./init.ps1 wezterm` symlink setup):

```powershell
wezterm --config-file "$env:USERPROFILE/.config/wezterm/wezterm.lua" show-keys
```

## Quick checks

- Print only custom key lines:

```bash
wezterm --config-file "./wezterm/wezterm.lua" show-keys | rg "LEADER|user-defined|preset-dev-1|trigger-tab-title"
```

- If `wezterm` is not found, verify installation:

```bash
wezterm --version
```
