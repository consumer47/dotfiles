# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# Check if SSH agent is already running
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
fi

if ! ssh-add -l > /dev/null 2>&1; then
    ssh-add ~/.ssh/id_rsa_hapeArchibald > /dev/null 2>&1
    ssh-add ~/.ssh/id_rsa_rb_led_pi_2024_11_13 > /dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519 > /dev/null 2>&1
    ssh-add ~/.ssh/id_rsa_ubuntu_work > /dev/null 2>&1
fi


if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/Apps/nvim-linux64/bin:$HOME/bin:/usr/local/bin:$PATH
[[ -f $HOME/.fzf.zsh ]] && source $HOME/.fzf.zsh
# source ~/.fzf.zsh

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

_z_cd() {
    cd "$@" || return "$?"

    if [ "$_ZO_ECHO" = "1" ]; then
        echo "$PWD"
    fi
}

z() {
    if [ "$#" -eq 0 ]; then
        _z_cd ~
    elif [ "$#" -eq 1 ] && [ "$1" = '-' ]; then
        if [ -n "$OLDPWD" ]; then
            _z_cd "$OLDPWD"
        else
            echo 'zoxide: $OLDPWD is not set'
            return 1
        fi
    else
        _zoxide_result="$(zoxide query -- "$@")" && _z_cd "$_zoxide_result"
    fi
}

zi() {
    _zoxide_result="$(zoxide query -i -- "$@")" && _z_cd "$_zoxide_result"
}


alias za='zoxide add'

alias zq='zoxide query'
alias zqi='zoxide query -i'

alias zr='zoxide remove'
zri() {
    _zoxide_result="$(zoxide query -i -- "$@")" && zoxide remove "$_zoxide_result"
}


_zoxide_hook() {
    zoxide add "$(pwd -L)"
}

chpwd_functions=(${chpwd_functions[@]} "_zoxide_hook")
# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# vim-interaction 
    plugins=(vim-interaction zoxide ssh git zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode fzf)

# ZSH_THEME="powerlevel10k/powerlevel10k"
source $ZSH/oh-my-zsh.sh

# User configuration
# eval "$(zoxide init --cmd cd zsh)"
# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

alias MyShortcuts='batcat /home/dennis/dotfiles/shortcuts/shortcuts'

alias please='sudo $(fc -ln -1)'
alias pushcommitadddotfiles='cd ~/dotfiles/ && git add . && git commit -m "..." && git push'
alias clippit="xclip -selection clipboard"

alias tmux_clean='tmux list-sessions -F "#{session_attached} #{session_id}" | awk "\$1 == 0 {print \$2}" | xargs -I {} tmux kill-session -t {}'


alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias ll='ls -al'
bindkey -v
export KEYTIMEOUT=1

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
PATH="/home/dennis/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/home/dennis/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/dennis/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/dennis/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/dennis/perl5"; export PERL_MM_OPT;

jibidi() {
    export OPENAI_API_KEY=$(<~/.openai_api_key)
    python3 ~/gpt_py_cli/CliManager.py "$@"
    unset OPENAI_API_KEY
}
gpt() {
    export OPENAI_API_KEY=$(<~/.openai_api_key)
     cd ~/gpt_py_cli/
    python3 CliManager.py "$@"
    unset OPENAI_API_KEY
}

# create new tmux alaritty session with same path
function cw() {
   # Get the current directory path
   local current_path=$(pwd)
   # Open a new Alacritty window that starts a tmux session in the current directory
   alacritty -e tmux new-session -c "$current_path" &
}


export PATH=$PATH:$HOME/.todo.txt-cli
export EDITOR='nvim'
export BROWSER='firefox'
alias control_arch='ssh dennis@192.168.178.151 -X x2x -west -to :0'
alias control_pi='ssh pi@192.168.178.89 -X x2x -west -to :0'
alias control_dolphin='ssh dennis@DebbyTheDolphine -X x2x -west -to :0'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias t="todo.sh"
alias n="nvim"
alias b="batcat"
alias a="jibidi -t \""
alias pinkel="ping 8.8.8.8"
alias :e="nvim"
alias nicer_slicer_gui="ssh -X dennis@NicerSlicer 'prusa-slicer'"
alias k='feh ~/keyboard_layouts/*'
alias ra='joshuto'
alias addcard='/home/dennis/workbench/rust_testing/anki_card_manager/target/debug/anki_card_manager'
export WLAN_OUTDOOR="FRITZ\!Box 7490"
export WLAN_OUTDOOR_PASS="68631738386882378679"
export WLAN_HOME="FRITZ\!Box 7590 PG"
export WLAN_HOME_PASS="07483358857555792066"
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export PATH=$PATH:~/.local/share/flatpak/exports/bin
export PATH=$PATH:/var/lib/flatpak/exports/bin
# export PATH=$PATH:/root/.cargo/bin
export PATH="$HOME/.cargo/bin:$PATH"
source ~/powerlevel10k/powerlevel10k.zsh-theme
