#!/usr/bin/env python3
"""bobr-agent-exec-guest -- run a command on the QEMU guest over its ttyS1 diag serial.

The qemu runner wires the guest's second serial port (ttyS1) to a host unix
socket in the working directory (server=on,wait=off), and every image runs an
autologin-root diag console on ttyS1 (diag-console.service, in the base
system-runtime-files). Each launcher names its socket per variant so several
guests can run at once: bobr-run-qemu.sh -> diag.sock, bobr-run-qemu-weston.sh
-> diag-weston.sock, bobr-run-qemu-gnome.sh -> diag-gnome.sock; pass the right
one with --sock. This script connects to that socket, runs one command in the
guest's root shell, and prints its output -- turning the serial console into a
clean request/response the agent can drive from its Bash without any MCP
(unix-socket connect needs no privilege, and the working dir is local ext4 on
the same kernel).

Robustness: output is delimited by nonce markers emitted by the guest shell, so
login banners, the prompt, and input echo are all ignored -- only the bytes the
command actually produced are returned. A Ctrl-C and `stty -echo` are sent first
to recover from a stuck line and quiet the console.

A bare --sock name resolves against the workspace root (where the launchers
create the sockets), so this works from any directory:
    python3 bobr-recipes/tools/bobr-agent-exec-guest.py 'journalctl -b | tail'
    python3 bobr-recipes/tools/bobr-agent-exec-guest.py --timeout 60 \
        'systemctl --user status weston.service'
    python3 bobr-recipes/tools/bobr-agent-exec-guest.py --sock diag-weston.sock \
        'ls /dev/dri'

Exit code mirrors the guest command's exit code; 3 = connection problem,
4 = timed out waiting for the guest to finish.
"""

from __future__ import annotations

import argparse
import base64
import os
import secrets
import socket
import sys
import time

# The launchers create the diag socket in the directory they are started from --
# the workspace root (this script lives at <root>/bobr-recipes/tools/). Resolve
# the default and any relative --sock against that root, so the tool works from
# any working directory; an absolute --sock is used as-is.
SOCK_DIR = os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
)
DEFAULT_SOCK = "diag.sock"


def resolve_sock(sock: str) -> str:
    return sock if os.path.isabs(sock) else os.path.join(SOCK_DIR, sock)


def run(sock_path: str, command: str, timeout: float) -> tuple[int, str]:
    nonce = secrets.token_hex(8)
    begin = f"{nonce}BEGIN"
    end = f"{nonce}END:"

    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(timeout)
    try:
        s.connect(sock_path)
    except (FileNotFoundError, ConnectionRefusedError, OSError) as e:
        return 3, f"bobr-agent-exec-guest: cannot connect to {sock_path}: {e}"

    # Clear any half-typed line, quiet echo/prompt, then run the command wrapped
    # in nonce markers. The command is base64-encoded and decoded+run by a fresh
    # bash on the guest, so it is a single line over the serial regardless of
    # newlines/quotes, and the (possibly echoed) wrapper never itself contains the
    # expanded markers -- they only appear once printf expands "$M" in real output.
    b64 = base64.b64encode(command.encode()).decode()
    wrapper = (
        f"M={nonce}; stty -echo 2>/dev/null; export PS1=''; "
        f'printf "\\n%sBEGIN\\n" "$M"; '
        f"printf '%s' '{b64}' | base64 -d | bash 2>&1; "
        f'printf "\\n%sEND:%s\\n" "$M" "$?"\n'
    )
    try:
        s.sendall(b"\x03")           # Ctrl-C: drop any partial input line
        time.sleep(0.1)
        s.sendall(wrapper.encode())
    except OSError as e:
        s.close()
        return 3, f"bobr-agent-exec-guest: send failed: {e}"

    buf = ""
    deadline = time.monotonic() + timeout
    try:
        while time.monotonic() < deadline:
            s.settimeout(max(0.1, deadline - time.monotonic()))
            try:
                chunk = s.recv(65536)
            except socket.timeout:
                break
            if not chunk:
                break
            buf += chunk.decode("utf-8", "replace")
            if end in buf and begin in buf:
                break
    finally:
        s.close()

    if begin not in buf or end not in buf:
        return 4, f"bobr-agent-exec-guest: timed out after {timeout}s; raw tail:\n{buf[-2000:]}"

    body = buf.split(begin, 1)[1]
    body, rest = body.split(end, 1)
    # exit code is whatever follows END: up to the newline
    code_str = rest.lstrip().split("\n", 1)[0].strip()
    try:
        code = int(code_str)
    except ValueError:
        code = 0
    return code, body.strip("\r\n")


def main() -> None:
    ap = argparse.ArgumentParser(description="run a command on the QEMU guest via ttyS1")
    ap.add_argument("command", help="shell command to run in the guest (root)")
    ap.add_argument(
        "--sock",
        default=DEFAULT_SOCK,
        help=f"diag socket; a relative name resolves against {SOCK_DIR} "
        f"(default {DEFAULT_SOCK})",
    )
    ap.add_argument("--timeout", type=float, default=30.0, help="seconds (default 30)")
    args = ap.parse_args()
    code, out = run(resolve_sock(args.sock), args.command, args.timeout)
    sys.stdout.write(out + ("\n" if out and not out.endswith("\n") else ""))
    sys.exit(code)


if __name__ == "__main__":
    main()
