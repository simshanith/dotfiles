if type __git_complete &> /dev/null; then
  _branch () {
    delete="${words[1]}"
    if [ "$delete" == "-d" ] || [ "$delete" == "-D" ]; then
      _git_branch
    else
      _git_checkout
    fi
  }

  __git_complete branch _branch
  __git_complete merge _git_merge
fi;
