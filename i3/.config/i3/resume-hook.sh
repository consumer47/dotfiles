#!/usr/bin/env bash

# Resume Hook Script
# Removes suspend marker when system resumes
# This should be called by systemd or a resume hook

SUSPEND_MARKER="/tmp/suspend-marker.flag"

# Remove suspend marker if it exists
[ -f "$SUSPEND_MARKER" ] && rm -f "$SUSPEND_MARKER"
