# Don't check mail when opening terminal.
unset MAILCHECK

# Enable some Bash 4 features when possible:
# * Recursive globbing, e.g. `echo **/*.txt`
shopt -s globstar 2> /dev/null

shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# up the maximum open files
# (not working in El Capitan)
# ulimit -n 16384
