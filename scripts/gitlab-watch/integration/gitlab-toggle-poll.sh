#!/usr/bin/env bash
# Toggle GitLab watch polling (systemd user timer) and trigger immediate refresh on enable.
set -euo pipefail

TIMER_UNIT="${GITLAB_WATCH_TIMER_UNIT:-gitlab-watch-poll.timer}"
SERVICE_UNIT="${GITLAB_WATCH_SERVICE_UNIT:-gitlab-watch-poll.service}"
WATCH_ROOT="${GITLAB_WATCH_ROOT:-$HOME/dotfiles/scripts/gitlab-watch}"
SYSTEMD_SRC_DIR="$WATCH_ROOT/systemd"
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a "GitLab watch" "$1" "${2:-}" || true
}

if ! command -v systemctl >/dev/null 2>&1; then
  notify "GitLab watch toggle failed" "systemctl not available."
  exit 1
fi

# Self-heal missing user unit links so toggle works after fresh boot/machine setup.
mkdir -p "$SYSTEMD_USER_DIR"
if [[ -f "$SYSTEMD_SRC_DIR/$SERVICE_UNIT" && ! -e "$SYSTEMD_USER_DIR/$SERVICE_UNIT" ]]; then
  ln -s "$SYSTEMD_SRC_DIR/$SERVICE_UNIT" "$SYSTEMD_USER_DIR/$SERVICE_UNIT"
fi
if [[ -f "$SYSTEMD_SRC_DIR/$TIMER_UNIT" && ! -e "$SYSTEMD_USER_DIR/$TIMER_UNIT" ]]; then
  ln -s "$SYSTEMD_SRC_DIR/$TIMER_UNIT" "$SYSTEMD_USER_DIR/$TIMER_UNIT"
fi
systemctl --user daemon-reload

if systemctl --user is-active --quiet "$TIMER_UNIT"; then
  systemctl --user stop "$TIMER_UNIT"
  notify "GitLab watch disabled" "Polling stopped."
  exit 0
fi

systemctl --user start "$TIMER_UNIT"
# Run one immediate refresh so Polybar updates right away.
systemctl --user start "$SERVICE_UNIT" || true
notify "GitLab watch enabled" "Polling started."
