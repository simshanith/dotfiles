# include svn status information
sim_scm_prompt() {
  scm
  if [ "$SCM" == "$SCM_NONE" ]; then
    return
  elif [ "$SCM" == "$SCM_GIT" ]; then
    echo "$background_cyan   $normal ${blue}$SCM_GIT${normal}$(git_prompt_status)"
  elif [ "$SCM" == "$SCM_SVN" ]; then
    echo "$background_cyan   $normal ${blue}$SCM_SVN${normal}$(svn_prompt_status)"
  else
    echo "$background_cyan   $normal [$(scm_prompt_info)] "
  fi
  echo "\r"
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
  PS1="\n${bold_white}${background_blue} ${clock} ${normal}${reset_color} $(scm_char) [$THEME_PROMPT_HOST_COLOR\u@${THEME_PROMPT_HOST}$reset_color]
${black}${background_white} \w ${normal}${reset_color}
$(sim_scm_prompt)$reset_color${bold_white}${background_orange} λ ${normal}${reset_color} "
  PS2='> '
  PS4='+ '
}

export history_command='history -a;'
history_command='history -a; echo "$$ $USER $(history 1)" >> ~/.bash_eternal_history'

PROMPT_COMMAND="prompt_setter; $history_command"
