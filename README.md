# config

My personal Linux configuration files following the XDG Base Directory Specification.

This repository mirrors ~/.config/ and can be reused across different machines.

## Init

Link an app directory from this repo into your host's config directory:

```bash
./init.sh opencode
```

This creates a symlink from `<repo>/opencode/` to `${XDG_CONFIG_HOME:-~/.config}/opencode`. If the destination already exists and isn't the desired symlink, it is moved aside to `*.bak.<timestamp>`.

## OpenCode

OpenCode configuration lives in `opencode/`.

- `opencode/AGENTS.md`: default agent instructions (copied from `~/AGENTS.md`).
