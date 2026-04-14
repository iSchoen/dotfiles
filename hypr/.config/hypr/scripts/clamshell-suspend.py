#!/usr/bin/env python3
"""
clamshell-suspend.py
Listens for Hyprland monitor disconnect events.
If the lid is closed and no external monitors remain, suspends the system.
"""

import json
import os
import socket
import subprocess
import time

LID_STATE_PATH = "/proc/acpi/button/lid/LID0/state"
INTERNAL_DISPLAY = "eDP-2"


def get_socket_path():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    return f"{runtime_dir}/hypr/{sig}/.socket2.sock"


def is_lid_closed():
    try:
        with open(LID_STATE_PATH) as f:
            return "closed" in f.read()
    except FileNotFoundError:
        return False


def has_external_monitors():
    try:
        result = subprocess.run(
            ["hyprctl", "monitors", "-j"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        monitors = json.loads(result.stdout)
        return any(m["name"] != INTERNAL_DISPLAY for m in monitors)
    except Exception:
        return True  # Fail safe: assume external monitor exists on error


def main():
    sock_path = get_socket_path()
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(sock_path)

    buf = ""
    while True:
        data = sock.recv(4096).decode("utf-8", errors="replace")
        if not data:
            break
        buf += data
        while "\n" in buf:
            line, buf = buf.split("\n", 1)
            event = line.strip()
            if event.startswith("monitorremoved"):
                time.sleep(1)  # Let Hyprland state settle
                if is_lid_closed() and not has_external_monitors():
                    subprocess.run(["systemctl", "suspend"])


if __name__ == "__main__":
    main()
