# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

if [ -f "$HOME/.xprofile" ]; then
   . "$HOME/.xprofile"
fi 
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/home/dennis/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
. "$HOME/.cargo/env"


# for docker dev container in vscode: 
export DOCKER_BUILDKIT=0

if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
fi

if ! ssh-add -l > /dev/null 2>&1; then
    ssh-add ~/.ssh/id_rsa_hapeArchibald > /dev/null 2>&1
    ssh-add ~/.ssh/id_rsa_rb_led_pi_2024_11_13 > /dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519 > /dev/null 2>&1
    ssh-add ~/.ssh/id_rsa_ubuntu_work > /dev/null 2>&1
fi
