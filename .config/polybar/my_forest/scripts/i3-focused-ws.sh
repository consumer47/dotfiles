#!/usr/bin/env bash
# Print focused i3 workspace number for polybar (one digit / index only).
set -uo pipefail

emit() {
  i3-msg -t get_workspaces 2>/dev/null | jq -r '.[] | select(.focused == true) | .num' | head -1
}

emit || true
i3-msg -t subscribe -m '["workspace"]' 2>/dev/null | while IFS= read -r _; do
  emit || true
done
