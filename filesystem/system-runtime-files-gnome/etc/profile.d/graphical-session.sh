# Start the Wayland graphical session on the seat0 VT (tty1) login only. Guarded
# so the root serial console (ttyS0), su and ssh sessions are untouched. Hand
# the login session's identity to the user manager first, so the compositor
# (a user service under user@) can take control of seat0 via logind.
if [ "$(tty)" = "/dev/tty1" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
  systemctl --user import-environment XDG_SESSION_ID XDG_SEAT XDG_VTNR
  # Start the compositor; it pulls in graphical-session.target itself (that
  # target refuses manual start, so we must not start it directly).
  systemctl --user start weston.service
fi
