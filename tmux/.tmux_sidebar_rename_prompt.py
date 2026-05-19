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


window_id = os.environ.get("TMUX_SIDEBAR_WINDOW_ID") or tmux_value("#{window_id}")
window_name = os.environ.get("TMUX_SIDEBAR_WINDOW_NAME") or tmux_value("#{window_name}")
client_tty = os.environ.get("TMUX_SIDEBAR_CLIENT_TTY") or tmux_value("#{client_tty}")


def restore_sidebar_mode() -> None:
    if client_tty:
        subprocess.run(
            ["tmux", "switch-client", "-c", client_tty, "-T", "tmux-sidebar"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def rename_window(new_name: str) -> None:
    if new_name and new_name != window_name:
        subprocess.run(
            ["tmux", "rename-window", "-t", window_id, new_name],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


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
    if not sys.stdin.isatty():
        rename_window(window_name)
        restore_sidebar_mode()
        return 0

    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    prompt = "rename window: "
    buffer = window_name

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

    rename_window(buffer)
    restore_sidebar_mode()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
