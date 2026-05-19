#!/usr/bin/env bash
# Thin wrapper: Polybar lives under ~/.config; core script lives in dotfiles gitlab-watch.
: "${GITLAB_WATCH_ROOT:=$HOME/dotfiles/scripts/gitlab-watch}"
exec "$GITLAB_WATCH_ROOT/integration/gitlab-pipelines-polybar.sh"
