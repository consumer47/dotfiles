# Scrcpy window vanishing – analysis

## What we know

1. **When it happens**: Phone lock (and sometimes unlock) → scrcpy window vanishes and does not return.
2. **What we already tried**:
   - Removed all `for_window` rules for scrcpy (no i3 rule touches the window).
   - Stopped using scratchpad (window is normal floating).
   - Only `start_scrcpy.sh` applies layout once after 3s; no i3 config targets scrcpy.

## Possible causes

### A. i3 / config

- **Generic rule (line 314)**: `for_window [class=".*"] focus_on_window_activation focus`  
  Matches every window (regex `.*`). Only runs on *window activation* and only runs `focus`. Unlikely to make a window disappear.

- **Move to scratchpad (line 289)**: `bindsym $mod+Ctrl+s move scratchpad`  
  Moves the *focused* window to scratchpad. If Super+Ctrl+s is pressed while scrcpy is focused, the window would vanish (go to scratchpad). Only relevant if that keybind is used around the time of lock.

- **No other i3 rule** in this config targets `scrcpy` or would move/close a generic floating window on lock.

- **dynamic_workspaces.sh** (exec_always): Runs on reload and does `i3-msg restart`, which closes all windows. Only relevant if something (e.g. autorandr) triggers a reload when the phone locks (e.g. display change). Unlikely unless you use display hotplug at the same time.

**Conclusion**: From the config alone, i3 is unlikely to be the cause unless Super+Ctrl+s is hit by mistake or something triggers a reload/restart.

### B. scrcpy / Android (very likely)

- **Known behaviour**: When the device screen locks or goes to sleep, scrcpy often:
  - Shows a **black screen** (window stays, content vanishes), or
  - Loses the video stream; some builds or Android versions may close or hide the window.
- **--stay-awake**: Only works over **USB**. Over TCP/IP (WiFi) the phone can still lock; we use TCP/IP, so lock is not prevented by this flag.
- **Android 14+**: Display/encoder changes can make the stream stop or go black when the screen turns off; the window may stay black or the app may react by closing the window.

So “vanishes” can mean either:
- **Window still exists but is black** → scrcpy/Android stream issue, not i3.
- **Window is gone from the tree** → either scrcpy closed it, or i3 moved it (e.g. to scratchpad) or something triggered a restart.

## What to do next

1. **Run the diagnostic when it has just vanished**  
   Run:
   ```bash
   ~/.config/i3/scrcpy_vanish_diagnostic.sh
   ```
   It will print:
   - Whether the scrcpy process is running.
   - Whether any window with class `scrcpy` (or title containing `scrcpy`) still exists in the i3 tree, and where (workspace, scratchpad, output).
   That tells us: **window destroyed by app** vs **window still in i3** (e.g. in scratchpad).

2. **Avoid accidental “move to scratchpad”**  
   If you use Super+Ctrl+s, avoid having the phone window focused when you lock the machine or press that combo. Optionally change the binding or exclude scrcpy (e.g. with a different key for “move to scratchpad” or a script that never moves `[class="scrcpy"]`).

3. **If the window is gone and the process is still running**  
   Then scrcpy (or the system) closed/unmapped the window. Workarounds:
   - Prevent lock while mirroring: e.g. `adb shell settings put system screen_off_timeout 86400000` (long timeout) while using scrcpy, then set back when done.
   - Try scrcpy options that might help with black screen (e.g. `--render-driver=opengl`); see scrcpy issues #6491 / #5945.
   - Add a keybind to **restart scrcpy** (kill + start) so you can bring the mirror back without touching the phone.

4. **If the window still exists in the tree but you don’t see it**  
   Then i3 moved it (e.g. to scratchpad or another workspace). The diagnostic will show where; we can then add a keybind or script to “focus scrcpy” / “show scratchpad” so one key brings it back.

Use the diagnostic output to decide which of these applies and then apply the matching fix (i3 keybind vs scrcpy/ADB vs restart keybind).

---

## Changes made in this repo

- **Safe move to scratchpad**: `$mod+Ctrl+s` now runs `move_to_scratchpad_safe.sh`, which does **not** move the scrcpy window to scratchpad (so you can't lose the phone window by accident).
- **Restart scrcpy**: `$mod+Alt+Shift+b` runs `restart_scrcpy.sh` (kill scrcpy then start again). Use when the mirror has vanished to get it back without touching the phone.
- **Diagnostic**: Run `~/.config/i3/scrcpy_vanish_diagnostic.sh` right after the window vanishes; check `/tmp/scrcpy_vanish_diagnostic.log` and the terminal output.
