### path to bash it.
### needed for some themes.
export BASH_IT=$HOME/.fresh/source/revans/bash-it

source "$BASH_IT/themes/doubletime/doubletime.theme.bash"

sim_scm_prompt() {
  scm
  if [ "$SCM" == "$SCM_NONE" ]; then
    return
  elif [ "$SCM" == "$SCM_GIT" ]; then
    echo "${blue}$SCM_GIT${normal}$(git_prompt_status)"
  elif [ "$SCM" == "$SCM_SVN" ]; then
    echo "${blue}$SCM_SVN${normal}$(svn_prompt_status)"
  else
    echo "[$(scm_prompt_info)]"
  fi
}

svn_prompt_status() {
  local svn_status_output
  svn_status_output=$(svn status --xml 2> /dev/null )
  if [ -n "$(echo $svn_status_output | grep 'item=\"modified\"')" ]; then
     svn_status="${bold_yellow}^"
  elif [ -n "$(echo $svn_status_output | grep 'item=\"unversioned\"')" ]; then
     svn_status="${bold_cyan}+"
  elif [ -n "$(echo $svn_status_output | grep '/status')" ]; then
     svn_status="${green}✓"
  else
    svn_status="$(scm_prompt_info)"
  fi
  echo "[$svn_status${normal}]"

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
