#!/usr/bin/env bash
# Leader key "t" — Taskwarrior in Alacritty (leader-spec.md).
# Invoked as: alacritty -e ~/.config/i3/taskwarrior-terminal.sh
#
# `task next` often exits non-zero when there are no tasks; that is normal and does NOT close
# Alacritty. What *did* close the window: running this file with a zsh shebang loads
# ~/.zshenv (and friends); if ERR_EXIT is set there, the script exits before `exec zsh -i`.
# Bash ignores zsh startup files for this wrapper.
set +e
export PATH="/usr/local/bin:/usr/bin:/bin:${HOME}/.local/bin:${PATH}"

task next 2>/dev/null
echo
task list 2>/dev/null

exec zsh -i
