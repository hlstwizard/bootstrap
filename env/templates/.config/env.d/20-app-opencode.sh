export OPENCODE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
export OPENCODE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/opencode"

# Secrets should be managed via Bitwarden (~/.bw-env), not plaintext here.
# Example keys in ~/.bw-env:
# OPENAI_API_KEY|my-openai-key|password
# ANTHROPIC_API_KEY|my-anthropic-key|password
