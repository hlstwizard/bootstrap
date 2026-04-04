if [[ -o interactive ]] && (( $+builtins[zle] )); then
  autoload -Uz bracketed-paste-magic
  zle -N bracketed-paste bracketed-paste-magic
  bindkey '^[[200~' bracketed-paste
fi
