# Enable startup profiling when ZSH_PROFILE is set.
if [[ -n "${ZSH_PROFILE:-}" ]]; then
  zmodload zsh/zprof
fi

# Oh My Zsh install path and completion cache location.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump-${HOST%%.*}-${ZSH_VERSION}"
mkdir -p "${ZSH_COMPDUMP%/*}"

# Initialize Homebrew environment for both macOS and Linux.
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

# Skip compaudit on startup and disable OMZ auto-update checks.
ZSH_DISABLE_COMPFIX="true"
zstyle ':omz:update' mode disabled

# Keep a simple default theme and essential plugins only.
ZSH_THEME="robbyrussell"

if [[ -f "$HOME/.zsh_plugins" ]]; then
  source "$HOME/.zsh_plugins"
else
  plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search)
fi

source "$ZSH/oh-my-zsh.sh"

# Re-apply custom prompt after theme loading.
[[ -f "${ZSH_CUSTOM:-$ZSH/custom}/prompt.zsh" ]] && source "${ZSH_CUSTOM:-$ZSH/custom}/prompt.zsh"

# Load optional local environment.
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# Print profiling result at shell startup end.
if [[ -n "${ZSH_PROFILE:-}" ]]; then
  zprof
fi
