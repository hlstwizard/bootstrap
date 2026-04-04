export NVM_DIR="$HOME/.nvm"
_brew_prefix="$(brew --prefix)"
_nvm_sh="${_brew_prefix}/opt/nvm/nvm.sh"
_nvm_bash_completion="${_brew_prefix}/opt/nvm/etc/bash_completion.d/nvm"

# Lazy-load nvm and Node.js commands on first use.
_load_nvm() {
  if [[ -n "${__NVM_LOADED:-}" ]]; then
    return 0
  fi

  if [[ ! -s "$_nvm_sh" ]]; then
    return 1
  fi

  . "$_nvm_sh" --no-use

  if [[ -o interactive && -s "$_nvm_bash_completion" ]]; then
    . "$_nvm_bash_completion"
  fi

  __NVM_LOADED=1
}

_nvm_lazy_cmd() {
  local cmd="$1"
  shift

  _load_nvm || {
    echo "nvm is not installed or nvm.sh is missing" >&2
    return 127
  }

  unfunction "$cmd" 2>/dev/null || true

  if [[ "$cmd" != "nvm" ]]; then
    nvm use --silent default >/dev/null 2>&1 || true
  fi

  "$cmd" "$@"
}

for _cmd in nvm node npm npx corepack; do
  eval "${_cmd}() { _nvm_lazy_cmd ${_cmd} \"\$@\"; }"
done

unset _brew_prefix _nvm_sh _nvm_bash_completion
unset _cmd
