# Enable startup profiling when ZSH_PROFILE is set.
if [[ -n "${ZSH_PROFILE:-}" ]]; then
  zmodload zsh/zprof
fi

# Oh My Zsh install path and completion cache location.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump-${HOST%%.*}-${ZSH_VERSION}"
mkdir -p "${ZSH_COMPDUMP%/*}"

# Skip compaudit on startup and disable OMZ auto-update checks.
ZSH_DISABLE_COMPFIX="true"
zstyle ':omz:update' mode disabled

# Keep a simple default theme and essential plugins only.
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search)

source "$ZSH/oh-my-zsh.sh"

# Load optional local environment.
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# Print profiling result at shell startup end.
if [[ -n "${ZSH_PROFILE:-}" ]]; then
  zprof
fi
