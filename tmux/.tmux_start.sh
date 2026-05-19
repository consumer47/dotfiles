#!/usr/bin/env bash

# Usage:
#   tmux_start.sh [--new] <path-to-workspace>

set -euo pipefail

new_session=""
if [ "${1:-}" = "--new" ]; then
  new_session=1
  shift
fi

if [ -z "${1:-}" ]; then
  echo "Usage: $0 [--new] <path-to-workspace>"
  exit 1
fi

workspace=$(realpath "$1")
session_name=$(basename "$workspace" | tr ':.' '__')

if [ -n "$new_session" ]; then
  session_name="${session_name}-$(date +%H%M%S)"
fi

exec tmux new-session -A -s "$session_name" -c "$workspace"
