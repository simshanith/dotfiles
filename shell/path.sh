# ~/.path (sourced)
# All PATH entries live in ~/.path (dot_path) so they're available
# to both interactive shells (via zshrc -> shell/path.sh -> ~/.path)
# and login shells (via zprofile -> ~/.path).
[[ -r ~/.path ]] && source ~/.path
