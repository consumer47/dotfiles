#!/usr/bin/env bash
# Leader key "t" — taskwarrior-tui in Alacritty (leader-spec.md).
# Ensures `task` (e.g. /usr/local/bin from source build) is on PATH for the TUI.
set +e
export PATH="/usr/local/bin:/usr/bin:/bin:${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
exec taskwarrior-tui "$@"
