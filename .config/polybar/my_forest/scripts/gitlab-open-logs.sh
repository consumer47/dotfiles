#!/usr/bin/env bash
: "${GITLAB_WATCH_ROOT:=$HOME/dotfiles/scripts/gitlab-watch}"
"$GITLAB_WATCH_ROOT/integration/open-failure-logs.sh" &
