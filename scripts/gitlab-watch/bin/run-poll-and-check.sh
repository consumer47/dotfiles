#!/usr/bin/env bash
# Invoked by systemd user gitlab-watch-poll.service: refresh status.json then fetch failure logs from cache.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/poll-status.sh"
GITLAB_WATCH_USE_CACHED_STATUS=1 "$SCRIPT_DIR/pipeline-check.sh"
