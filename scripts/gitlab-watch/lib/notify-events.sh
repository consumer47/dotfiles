# shellcheck shell=bash
# Sourced after common.sh — gitlab_watch_notify_pipeline_changes prev_json new_json

gitlab_watch_status_in_progress() {
  case "$1" in
    running|pending|created|preparing|scheduled|waiting_for_resource|manual) return 0 ;;
    *) return 1 ;;
  esac
}

gitlab_watch_event_allowed_by_level() {
  local level=$1 event=$2
  case "$level" in
    none) return 1 ;;
    failures)
      [[ "$event" == failure ]] && return 0
      return 1
      ;;
    finish)
      case "$event" in success|failure|canceled) return 0 ;; *) return 1 ;; esac
      ;;
    all) return 0 ;;
    *) return 1 ;;
  esac
}

gitlab_watch_send_notification() {
  local urgency=$1 title=$2 body=$3
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "GitLab watch" -u "$urgency" "$title" "$body" 2>/dev/null && return 0
  fi
  echo "[gitlab-watch] $title — $body" >&2
}

# Compare previous and new status payloads; emit notify-send per rules (skip if host mismatch).
gitlab_watch_notify_pipeline_changes() {
  local prev_json=$1 new_json=$2
  [[ -n "$GITLAB_HOST" ]] || return 0

  local prev_host
  prev_host="$(echo "$prev_json" | jq -r '.host // empty' 2>/dev/null)" || return 0
  [[ "$prev_host" == "$GITLAB_HOST" ]] || return 0

  local new_row path new_pid new_st ref url old_row old_pid old_st eff ev title body urg

  while IFS= read -r new_row; do
    [[ -z "$new_row" ]] && continue
    path="$(echo "$new_row" | jq -r '.path')"
    new_pid="$(echo "$new_row" | jq -r '.pipeline_id // empty | tostring')"
    new_st="$(echo "$new_row" | jq -r '.status // empty')"
    ref="$(echo "$new_row" | jq -r '.ref // empty')"
    url="$(echo "$new_row" | jq -r '.web_url // empty')"

    old_row="$(echo "$prev_json" | jq -c --arg p "$path" '.repos[]? | select(.path == $p)' 2>/dev/null | head -n1)"
    [[ -z "$old_row" ]] && continue

    old_pid="$(echo "$old_row" | jq -r '.pipeline_id // empty | tostring')"
    old_st="$(echo "$old_row" | jq -r '.status // empty')"
    eff="$(gitlab_watch_effective_notify_level "$path")"

    body="$path"
    [[ -n "$ref" && "$ref" != "null" ]] && body+=$'\n'"Branch: $ref"
    [[ -n "$new_pid" && "$new_pid" != "null" ]] && body+=$'\n'"Pipeline #$new_pid"
    [[ -n "$url" && "$url" != "null" ]] && body+=$'\n'"$url"

    if [[ "$new_pid" != "$old_pid" ]] && [[ -n "$new_pid" && "$new_pid" != "null" ]]; then
      if gitlab_watch_status_in_progress "$new_st"; then
        ev=started
        title="Pipeline started"
        urg=low
      elif [[ "$new_st" == "success" ]]; then
        ev=success
        title="Pipeline succeeded"
        urg=normal
      elif [[ "$new_st" == "failed" ]]; then
        ev=failure
        title="Pipeline failed"
        urg=critical
      elif [[ "$new_st" == "canceled" ]]; then
        ev=canceled
        title="Pipeline canceled"
        urg=normal
      else
        continue
      fi
      gitlab_watch_event_allowed_by_level "$eff" "$ev" || continue
      gitlab_watch_send_notification "$urg" "$title" "$body"
      continue
    fi

    [[ "$new_pid" == "$old_pid" ]] && [[ -n "$new_pid" && "$new_pid" != "null" ]] || continue

    if gitlab_watch_status_in_progress "$old_st"; then
      if [[ "$new_st" == "success" ]]; then
        gitlab_watch_event_allowed_by_level "$eff" success || continue
        gitlab_watch_send_notification normal "Pipeline succeeded" "$body"
      elif [[ "$new_st" == "failed" ]]; then
        gitlab_watch_event_allowed_by_level "$eff" failure || continue
        gitlab_watch_send_notification critical "Pipeline failed" "$body"
      elif [[ "$new_st" == "canceled" ]]; then
        gitlab_watch_event_allowed_by_level "$eff" canceled || continue
        gitlab_watch_send_notification normal "Pipeline canceled" "$body"
      fi
    fi
  done < <(echo "$new_json" | jq -c '.repos[]?')
}
