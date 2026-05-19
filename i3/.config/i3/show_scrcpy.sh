#!/usr/bin/bash
# Focus (and center) the scrcpy window – no scratchpad, so lock/unlock won't make it vanish or fail to return.
i3-msg '[class="scrcpy"] focus; move position center'
