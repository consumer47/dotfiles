# i3 leader key experiment (spec)

## Leader

- **Chord:** `Mod4+space` (Super+Space)
- **Mechanism:** i3 **binding mode** named `leader` (not a timed leader; exit with `y` after action, or `Escape` / `q` / `Return` to cancel). A real timeout would need an external tool later.

## Goal (this iteration)

- **Two-step** flow: leader → key → action.
- **Rofi combi** (previous `Super+space` single chord) is now **leader then Space**.

## Actions (v0)

| After leader | Action |
|--------------|--------|
| `Space` | **Rofi combi** (`rofi -show combi`), then return to default mode |
| `y` | Full desktop screenshot **to clipboard** (`flameshot full -c`), then return to default mode |
| `t` | **taskwarrior-tui** (Rust TUI): `alacritty -e ~/.config/i3/taskwarrior-tui-launch.sh` — launcher sets `PATH` so `task` from `/usr/local/bin` is found. Install: `scripts/install-taskwarrior-tui-deb.sh` (`.deb` + sudo) or same script with `cargo` (no sudo, needs `~/.cargo/bin` on PATH — wired in `zsh/.zshrc`). |

## Related config (already present)

- `exec --no-startup-id flameshot` — daemon on login
- `mode "screenshot"` — `Super+Print` / `Super+Alt+s`; `f` runs `flameshot full` (to configured path/behavior, not necessarily clipboard)
- OCR binding uses `flameshot gui -r` + tesseract

## Notes

- `Super+space` enters leader only; **rofi** is on **leader + Space** (same combi as before, two steps).
- Passthrough inside `mode "mouse"`: `$mod+space` still enters leader.
