#!/usr/bin/bash
# Start scrcpy if not already running. Keep window floating (no scratchpad) so lock/unlock can't make it vanish.
DEVICE_IP="${DEVICE_IP:-192.168.178.171}"
DEVICE_PORT="${DEVICE_PORT:-5555}"
pgrep -x scrcpy >/dev/null && exit 0
scrcpy -s "${DEVICE_IP}:${DEVICE_PORT}" \
  --window-title "scrcpy-mirror" --turn-screen-off --disable-screensaver --show-touches --stay-awake \
  --bit-rate=8M --max-size=1080 --window-width=500 --max-fps=60 &
sleep 3
# Float, size, border only – no scratchpad (scratchpad + lock/unlock caused window to vanish).
i3-msg '[class="scrcpy"] floating enable, resize set 500 1080, border pixel 0, move position center' >/dev/null 2>&1
wait
