# Editors
alias vi="nvim"

_tailscale_app_cli="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
if [[ -x "$_tailscale_app_cli" ]]; then
  alias tailscale="$_tailscale_app_cli"
fi
unset _tailscale_app_cli
