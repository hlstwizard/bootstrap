if [[ -o interactive ]]; then
  PROMPT='%(?:%{$fg[green]%}%1{➜%} :%{$fg[red]%}%1{➜%} ) %{$fg[white]%}%m%{$reset_color%} %{$fg_bold[cyan]%}%c%{$reset_color%} $(git_prompt_info)'
fi
