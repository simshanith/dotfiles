### path to bash it.
### needed for some themes.
export BASH_IT=$HOME/.fresh/source/revans/bash-it

source "$BASH_IT/themes/doubletime/doubletime.theme.bash"

sim_scm_prompt() {
  scm
  if [ "$SCM" == "$SCM_NONE" ]; then
    return
  elif [ "$SCM" == "$SCM_GIT" ]; then
    echo "$(git_prompt_status)"
  else
    echo "[$(scm_prompt_info)]"
  fi
}

function prompt_setter() {
  # Save history
  history -a
  history -c
  history -r
  if [[ -z "$THEME_PROMPT_CLOCK_FORMAT" ]]
  then
      clock="\t"
  else
      clock=$THEME_PROMPT_CLOCK_FORMAT
  fi
  PS1="
$clock $(scm_char) [$THEME_PROMPT_HOST_COLOR\u@${THEME_PROMPT_HOST}$reset_color] $(virtualenv_prompt)
\w
$(sim_scm_prompt)$reset_color $ "
  PS2='> '
  PS4='+ '
}

PROMPT_COMMAND=prompt_setter
