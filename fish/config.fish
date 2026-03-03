# ~/.config/fish/config.fish

# ── Environment ──────────────────────────────────────────────────────────────
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER  "less -FX"

# Add ~/.local/bin to PATH if not already present
fish_add_path ~/.local/bin

# ── Aliases ──────────────────────────────────────────────────────────────────
abbr -a -- ls  'ls --color=auto'
abbr -a -- ll  'ls -lh --color=auto'
abbr -a -- la  'ls -lAh --color=auto'
abbr -a -- vim nvim
abbr -a -- g   git

# ── Prompt ───────────────────────────────────────────────────────────────────
# Use Starship if available, otherwise keep the default Fish prompt
if command -q starship
    starship init fish | source
end
