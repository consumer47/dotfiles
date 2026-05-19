#!/usr/bin/env bash
: "${GITLAB_WATCH_ROOT:=$HOME/dotfiles/scripts/gitlab-watch}"
exec "$GITLAB_WATCH_ROOT/integration/gitlab-smart-action.sh"
