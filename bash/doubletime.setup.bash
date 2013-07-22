# include svn status information
sim_scm_prompt() {
  scm
  local sim_scm_prompt_prefix
  sim_scm_prompt_prefix="$background_cyan   $normal ${blue}$SCM${normal}"
  if [ "$SCM" == "$SCM_NONE" ]; then
    return
  elif [ "$SCM" == "$SCM_GIT" ]; then
    echo "$sim_scm_prompt_prefix $(git_prompt_status)"
  elif [ "$SCM" == "$SCM_SVN" ]; then
    echo "$sim_scm_prompt_prefix $(svn_prompt_status)"
  else
    echo "$sim_scm_prompt_prefix [$(scm_prompt_info)] "
  fi
  echo "\r"
}

svn_prompt_status() {
  local svn_status_output
  svn_status_output=$(svn status --xml 2> /dev/null )
  if [ -n "$(echo $svn_status_output | grep 'item=\"modified\"')" ]; then
     svn_status="${yellow}^"
  elif [ -n "$(echo $svn_status_output | grep 'item=\"unversioned\"')" ]; then
     svn_status="${cyan}+"
  elif [ -n "$(echo $svn_status_output | grep '/status')" ]; then
     svn_status="${green}✓"
  else
    svn_status="$(scm_prompt_info)"
  fi
  echo "[$svn_status${normal}]"

}


# override bash-it echo -e with unescaped version
function scm_char {
  scm_prompt_char
  echo "$SCM_CHAR"
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
      clock="$THEME_PROMPT_CLOCK_FORMAT"
  fi
  PS1="\n${bold_white}${background_blue} ${clock} ${normal} $(scm_char) [$THEME_PROMPT_HOST_COLOR\u@${THEME_PROMPT_HOST}$normal]
${black}${background_white} \w ${normal}
$(sim_scm_prompt)${bold_white}${background_orange} λ ${normal} "
  PS2='> '
  PS4='+ '
}

export history_command='history -a;'
history_command='history -a; echo "$$ $USER $(history 1)" >> ~/.bash_eternal_history'

PROMPT_COMMAND="prompt_setter; $history_command"
