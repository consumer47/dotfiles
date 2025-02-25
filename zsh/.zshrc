# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Powerlevel10k Config
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source ~/powerlevel10k/powerlevel10k.zsh-theme

# Oh My Zsh setup
export ZSH="$HOME/.oh-my-zsh"
plugins=(vim-interaction zoxide ssh git zsh-autosuggestions zsh-syntax-highlighting fzf)
source $ZSH/oh-my-zsh.sh

chpwd_functions=(${chpwd_functions[@]} "_zoxide_hook")

# Oh My Zsh Update Settings
zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 13
ENABLE_CORRECTION="true"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Load Common Configuration
[ -f ~/.commonrc ] && source ~/.commonrc
[ -f ~/.privaterc ] && source ~/.privaterc
