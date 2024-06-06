# .fzf.zsh

bindkey '^T' fzf-file-widget

# Improved Key Bindings
bindkey '^F' fzf-file-widget

   fzf-history-widget() {
       local selected_command
       selected_command=$(fc -l -1000 | fzf --query="$LBUFFER") || return
       BUFFER=$selected_command
       zle accept-line
   }
   zle -N fzf-history-widget
bindkey '^R' fzf-history-widget


# Useful Aliases
alias fzg='fzf --preview "bat --style=numbers --color=always --line-range :500 {}" < <(git ls-files)'
alias fzgrep='fzf --preview "grep --color=always -C {}"'

# Custom Functions
# Git checkout
fzf-git-checkout() {
  local branches sha
  branches=$(git branch -a | sed 's/remotes\/origin\///' | sort | uniq)
  sha=$(echo "$branches" | fzf +s +m -e)
  [ -n "$sha" ] && git checkout "$sha"
}



# Customize FZF Options
export FZF_DEFAULT_OPTS='--preview "bat --style=numbers --color=always --line-range :500 {}"'
export FZF_DEFAULT_OPTS='--layout=reverse --info=inline'

# Enhance Tab Completion (assuming you use zinit for plugin management)
if type zinit &>/dev/null; then
  zinit light Aloxaf/fzf-tab
fi

# Ripgrep Integration
RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
export FZF_DEFAULT_COMMAND="$RG_PREFIX ''"
fzf-file-widget() {
  local file
  file="$(eval "$FZF_DEFAULT_COMMAND" | fzf --ansi --preview 'bat --style=numbers --color=always --line-range :500 {}')"
  if [[ -n "$file" ]]; then
    LBUFFER+="$(echo $file | awk '{print $4}')"
    zle redisplay
  fi
}
zle -N fzf-file-widget
bindkey '^f' fzf-file-widget

# Autojump Integration
fzf-jump() {
  local dir
  dir=$(autojump --complete "$1" | fzf +m)
  if [[ -n "$dir" ]]; then
    cd "$dir"
  fi
}
alias j="fzf-jump"

# SSH Connection
ssh-fzf() {
  local host
  host=$(grep 'Host ' ~/.ssh/config | awk '{print $2}' | fzf)
  if [[ -n $host ]]; then
    ssh "$host"
  fi
}
# alias ssh="ssh-fzf"

# Bat (cat replacement)
export FZF_DEFAULT_COMMAND='fd --type f'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"

