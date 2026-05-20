#!/usr/bin/env bash
set -euo pipefail

site_link="$HOME/.ssh/config.d/05-site.conf"
home_site="$HOME/.ssh/config.d/sites/home.conf"
work_site="$HOME/.ssh/config.d/sites/work.conf"

current_target="$(readlink -f "$site_link" 2>/dev/null || true)"

if [[ "$current_target" == "$home_site" ]]; then
  next_target="$work_site"
  next_name="work"
  route="jump via rtb-service-pi"
elif [[ "$current_target" == "$work_site" ]]; then
  next_target="$home_site"
  next_name="home"
  route="direct"
else
  next_target="$work_site"
  next_name="work"
  route="jump via rtb-service-pi"
fi

ln -sfn "$next_target" "$site_link"

if command -v notify-send >/dev/null 2>&1; then
  notify-send -a "SSH site" -u low "SSH: $next_name" "$route" 2>/dev/null || true
fi
