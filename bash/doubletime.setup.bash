# Use FQDN
THEME_PROMPT_HOST="$(hostname -f)"

# include svn status information
sim_scm_prompt() {
  scm
  local sim_scm_prompt_prefix
  sim_scm_prompt_prefix="$background_cyan   $normal ${blue}$SCM${normal}"
  if [ "$SCM" == "$SCM_NONE" ]; then
    echo
    return
  elif [ "$SCM" == "$SCM_GIT" ]; then
    echo "$sim_scm_prompt_prefix $(git_prompt_status)\n"
  elif [ "$SCM" == "$SCM_SVN" ]; then
    echo "$sim_scm_prompt_prefix $(svn_prompt_status)\n"
  else
    echo "$sim_scm_prompt_prefix [$(scm_prompt_info)]\n"
  fi
}

svn_prompt_status() {
  echo 
}

itermMark() {
  if [[ "$TERM_PROGRAM" == 'iTerm.app' ]] && [[ $(type -t iterm2_prompt_mark) == 'function' ]]
  then
    echo "\[$(iterm2_prompt_mark)\]"
  fi
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

  if [[ -z "$SSH_CLIENT" ]]
  then
      ssh_prompt=""
  else
      ssh_prompt="${bold_white}${background_cyan} ssh ${normal}"
  fi
  PS1="\n${bold_white}${background_blue} ${clock} ${normal} $(scm_char) [$THEME_PROMPT_HOST_COLOR\u@${THEME_PROMPT_HOST}${normal}]
$ssh_prompt${black}${background_white} \w ${normal}\n$(sim_scm_prompt)$(itermMark)${bold_white}${background_orange} λ ${normal} "
  PS2='> '
  PS4='+ '
}

export history_command='history -a;'
history_command='history -a; echo "$$ $USER $(history 1)" >> ~/.bash_eternal_history'

PROMPT_COMMAND="prompt_setter; $history_command"
