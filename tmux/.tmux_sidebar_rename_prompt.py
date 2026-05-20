#!/usr/bin/env python3

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import termios
import tty


def tmux_value(expr: str, default: str = "") -> str:
    try:
        return subprocess.check_output(
            ["tmux", "display-message", "-p", expr],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except Exception:
        return default


def looks_like_format_literal(value: str) -> bool:
    return value.startswith("#{") and value.endswith("}")


argv = sys.argv[1:]

target_kind = argv[0] if len(argv) > 0 and argv[0] in {"pane", "session", "window"} else os.environ.get("TMUX_SIDEBAR_RENAME_KIND", "window")
target_id = argv[1] if len(argv) > 1 else os.environ.get("TMUX_SIDEBAR_TARGET_ID", "")
current_name = argv[2] if len(argv) > 2 else os.environ.get("TMUX_SIDEBAR_CURRENT_NAME", "")
restore_arg = argv[3] if len(argv) > 3 else ""
client_arg = argv[4] if len(argv) > 4 else ""
client_tty = client_arg or os.environ.get("TMUX_SIDEBAR_CLIENT_TTY") or tmux_value("#{client_tty}")
restore_sidebar_mode = restore_arg == "1" or os.environ.get("TMUX_SIDEBAR_RESTORE_MODE", "") == "1"

if looks_like_format_literal(target_id):
    target_id = ""
if looks_like_format_literal(current_name):
    current_name = ""

if not target_id:
    if target_kind == "pane":
        target_id = tmux_value("#{pane_id}")
        current_name = current_name or tmux_value("#{pane_title}")
    elif target_kind == "session":
        target_id = tmux_value("#{session_name}")
        current_name = current_name or tmux_value("#{session_name}")
    else:
        target_kind = "window"
        target_id = tmux_value("#{window_id}")
        current_name = current_name or tmux_value("#{window_name}")


def restore_mode() -> None:
    if restore_sidebar_mode and client_tty:
        subprocess.run(
            ["tmux", "switch-client", "-c", client_tty, "-T", "tmux-sidebar"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def rename_target(new_name: str) -> None:
    if not new_name or new_name == current_name:
        return

    command = {
        "pane": "select-pane",
        "session": "rename-session",
        "window": "rename-window",
    }[target_kind]

    args = ["tmux", command, "-t", target_id]
    if target_kind == "pane":
        args.extend(["-T", new_name])
    else:
        args.append(new_name)

    subprocess.run(args, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def redraw(prompt: str, buffer: str) -> None:
    width = shutil.get_terminal_size((50, 18)).columns
    visible = buffer
    limit = max(0, width - len(prompt) - 5)
    if len(visible) > limit:
        visible = "..." + visible[-limit:] if limit else "..."
    sys.stdout.write("\r\033[K")
    sys.stdout.write(f"{prompt}{visible}")
    sys.stdout.flush()


def main() -> int:
    prompt = f"rename {target_kind}: "

    if not sys.stdin.isatty():
        rename_target(current_name)
        restore_mode()
        return 0

    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    buffer = current_name

    try:
        tty.setraw(fd)
        redraw(prompt, buffer)

        while True:
            ch = os.read(fd, 1)
            if not ch:
                break

            key = ch.decode("utf-8", errors="ignore")
            if key in ("\r", "\n"):
                break
            if key == "\x1b":
                if buffer:
                    buffer = ""
                    redraw(prompt, buffer)
                    continue
                break
            if key in ("\x7f", "\b"):
                buffer = buffer[:-1]
                redraw(prompt, buffer)
                continue

            buffer += key
            redraw(prompt, buffer)

    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        sys.stdout.write("\r\033[K")
        sys.stdout.flush()

    rename_target(buffer)
    restore_mode()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
