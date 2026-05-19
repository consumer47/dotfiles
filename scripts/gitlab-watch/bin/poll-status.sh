#!/usr/bin/env bash
# Poll GitLab → notify-send on pipeline changes → atomic status.json (systemd ~1/min).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITLAB_WATCH_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$GITLAB_WATCH_ROOT/lib/common.sh"
# shellcheck source=../lib/notify-events.sh
source "$GITLAB_WATCH_ROOT/lib/notify-events.sh"

CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config|--watchlist) CONFIG_FILE="$2"; shift 2 ;;
    --logdir) GITLAB_WATCH_LOGDIR="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: poll-status.sh [--config FILE] [--logdir DIR]"
      echo "  (GITLAB_WATCH_CONFIG or deprecated GITLAB_WATCHLIST overrides default path.)"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$CONFIG_FILE" ]] || CONFIG_FILE="$(gitlab_watch_resolve_config_file "$GITLAB_WATCH_ROOT")"

[[ -f "$CONFIG_FILE" ]] || { echo "Config not found: $CONFIG_FILE (copy gitlab-watch.conf.example)" >&2; exit 1; }

gitlab_watch_load_config "$CONFIG_FILE"
GITLAB_HOST="$(gitlab_watch_trim "${GITLAB_HOST:-$host_from_file}")"
[[ -n "$GITLAB_HOST" ]] || { echo "No GitLab host in config or GITLAB_HOST" >&2; exit 1; }

command -v glab >/dev/null 2>&1 || { echo "glab not found" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq not found" >&2; exit 1; }
[[ ${#repos[@]} -gt 0 ]] || { echo "No repos in config" >&2; exit 1; }

STATE_ROOT="$(gitlab_watch_default_state_root)"
mkdir -p "$STATE_ROOT"
STATUS_FILE="$STATE_ROOT/status.json"

PREV_JSON='{"repos":[]}'
if [[ -f "$STATUS_FILE" ]]; then
  PREV_JSON="$(cat "$STATUS_FILE")" || PREV_JSON='{"repos":[]}'
fi
if ! echo "$PREV_JSON" | jq -e . >/dev/null 2>&1; then
  PREV_JSON='{"repos":[]}'
fi

items=()
for repo in "${repos[@]}"; do
  enc="$(urlencode_project "$repo")"
  if ! pipelines_json="$(glab_api_get "projects/${enc}/pipelines?per_page=1&order_by=id&sort=desc")"; then
    echo "[$repo] glab api pipelines failed" >&2
    exit 1
  fi
  item="$(echo "$pipelines_json" | jq -c --arg p "$repo" '
    if (type == "array") and (length > 0) and (.[0].id != null) then
      {
        path: $p,
        pipeline_id: .[0].id,
        status: .[0].status,
        web_url: .[0].web_url,
        ref: .[0].ref,
        started_at: (.[0].started_at // .[0].created_at // .[0].updated_at // null)
      }
    else
      {path: $p, pipeline_id: null, status: "none", web_url: null, ref: null, started_at: null}
    end
  ')"
  items+=("$item")
done

json_array="$(printf '%s\n' "${items[@]}" | jq -s '.')"
payload="$(jq -n --arg h "$GITLAB_HOST" --argjson repos "$json_array" \
  '{updated_at: (now | todate), host: $h, repos: $repos}')"

gitlab_watch_notify_pipeline_changes "$PREV_JSON" "$payload"

tmp="$(mktemp "$STATE_ROOT/status.json.XXXXXX")"
printf '%s\n' "$payload" >"$tmp"
mv "$tmp" "$STATUS_FILE"
