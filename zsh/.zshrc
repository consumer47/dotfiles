# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# History configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY          # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS       # Don't record an entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS   # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS      # Do not display a line previously found
setopt HIST_IGNORE_SPACE      # Don't record an entry starting with a space
setopt HIST_SAVE_NO_DUPS      # Don't write duplicate entries in the history file
setopt HIST_REDUCE_BLANKS      # Remove superfluous blanks before recording entry
setopt INC_APPEND_HISTORY      # Write to history file immediately, not when shell exits

# Vi mode configuration
bindkey -v                      # Enable vi mode
export KEYTIMEOUT=1            # Reduce delay when switching modes (ESC key)

# Vi mode keybindings
bindkey '^?' backward-delete-char  # Backspace works in insert mode
bindkey '^[[3~' delete-char        # Delete key works in insert mode
bindkey '^[[1~' beginning-of-line  # Home key
bindkey '^[[4~' end-of-line        # End key

# Powerlevel10k Config
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=false
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source ~/powerlevel10k/powerlevel10k.zsh-theme

# Robbyrussell theme alternative (uncomment below and comment Powerlevel10k above to test)
# PROMPT='%n@%m %1~ %# '

eval "$(direnv hook zsh)"

# Initialize zoxide
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# Zsh plugins directory
ZSH_PLUGINS_DIR="$HOME/.zsh/plugins"

# Load zsh plugins individually
# zsh-autosuggestions - must be loaded before syntax-highlighting
if [[ -f "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# zsh-vi-man - Vi-style man pages
# https://github.com/TunaCuma/zsh-vi-man
if [[ -f "$ZSH_PLUGINS_DIR/zsh-vi-man/zsh-vi-man.plugin.zsh" ]]; then
  source "$ZSH_PLUGINS_DIR/zsh-vi-man/zsh-vi-man.plugin.zsh"
fi

# zsh-syntax-highlighting - must be loaded last
if [[ -f "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Load fzf keybindings (Ctrl+R for history search, etc.)
if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

# zoxide hook is automatically set up by zoxide init above

# function y() {
# 	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
# 	yazi "$@" --cwd-file="$tmp"
# 	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
# 		builtin cd -- "$cwd"
# 	fi
# 	rm -f -- "$tmp"
# }

# export PATH=/opt/st/stm32cubeide_1.19.0/:$PATH
# export PATH=$HOME/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin:$PATH
# Load Common Configuration
[ -f ~/.commonrc ] && source ~/.commonrc
[ -f ~/.privaterc ] && source ~/.privaterc
# export PATH=$PATH:/usr/libexec

# Slow down here?
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# [[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# [ -f ~/workbench/rtb-service-pi/targets/topo/topo-bike/completion.bash ] && source ~/workbench/rtb-service-pi/targets/topo/topo-bike/completion.bash
# [ -d "$HOME/workbench/rtb-service-pi/cli" ] && export PATH="$HOME/workbench/rtb-service-pi/cli:$PATH"

# [ -f "$HOME/.local/share/../bin/env" ] && . "$HOME/.local/share/../bin/env"

# Audinofy - audible CLI notifications
# alias audinofy='~/workbench_old/audio-signal-cli/audinofy'
# alias ay='~/workbench_old/audio-signal-cli/audinofy'
alias todo='nvim "$HOME/Documents/todo/$(date +%F).txt"'
alias todo_2='nvim "$HOME/Documents/todo2/$(date +%F).txt"'