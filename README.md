# dotfiles
vim tmux i3 zsh ...

## Scrcpy / Android

Mirror and control your Android phone from the desktop (i3 floating window).

- **Install:** `make install_scrcpy` (installs `scrcpy` and `adb`; Arch: `scrcpy` + `android-tools`, Debian/Ubuntu: `scrcpy` + `adb`).
- **One-time setup:** Connect phone via USB, enable USB debugging, run `adb tcpip 5555`. Put the phone on the same Wi‑Fi as the PC. Set the device IP in `~/.config/i3/adb_scrcpy.sh` (default `192.168.178.171:5555`). Optionally use `adbwifi` (alias to `~/bin/adbwifi.sh`) if you have it.
- **Keybindings (i3):**
  - `$mod+Shift+b` — start scrcpy (if not running)
  - `$mod+b` — focus phone window (bring to front, center)
  - `$mod+Alt+Shift+b` — restart scrcpy (kill + start; use when mirror vanished after lock)
  - `$mod+Shift+u` — unlock phone (runs `adb_unlock.sh`)
- **PIN:** Copy `~/.config/i3/adb_unlock.env.example` to `adb_unlock.env`, add `ADB_UNLOCK_PIN=1234`. This file is not in the repo (add to `.gitignore` if you track it).
- **Window vanishing after phone lock:** See `~/.config/i3/scrcpy_vanish_analysis.md`. Run `~/.config/i3/scrcpy_vanish_diagnostic.sh` right after it vanishes; use `$mod+Alt+Shift+b` to restart the mirror.
