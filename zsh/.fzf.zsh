# Setup fzf
# ---------
if [[ ! "$PATH" == */home/dennis/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/dennis/.fzf/bin"
fi

source <(fzf --zsh)
