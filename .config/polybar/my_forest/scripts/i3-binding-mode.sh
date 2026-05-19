#!/usr/bin/env bash
# Polybar: i3 binding mode at far left. Internal i3 <label-mode> hides when default — this keeps a slot.
set -uo pipefail
C_ACTIVE='#e60053'
C_DIM='#555555'

emit() {
  local n
  n=$(i3-msg -t get_binding_state 2>/dev/null | jq -r '.name // "default"')
  case "$n" in
    default | '')
      printf '%s\n' "%{F${C_DIM}}·%{F-}"
      ;;
    *)
      printf '%s\n' "%{F${C_ACTIVE}}${n}%{F-}"
      ;;
  esac
}

emit
i3-msg -t subscribe -m '["mode"]' 2>/dev/null | while IFS= read -r _; do
  emit
done
