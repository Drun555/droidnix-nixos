set -euo pipefail

profile_user="${USER:-$(id -un)}"
export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$profile_user/bin:$PATH"
export XDG_CONFIG_DIRS="/etc/xdg:/run/current-system/sw/etc/xdg${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}"
export XDG_DATA_DIRS="/run/current-system/sw/share:/etc/profiles/per-user/$profile_user/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
export XDG_MENU_PREFIX="gnome-flashback-"

if [[ -z "${DISPLAY:-}" ]]; then
  socket="$(
    # Android-owned Unix sockets are not reliably matched by GNU find's
    # `-type s` from inside DroidSpaces. xdpyinfo validates the candidate below.
    find /tmp/.X11-unix -maxdepth 1 -name 'X*' -printf '%f\n' 2>/dev/null \
      | sort -V \
      | tail -n 1
  )"

  if [[ -z "$socket" ]]; then
    echo "Termux:X11 socket not found under /tmp/.X11-unix." >&2
    echo "Start Termux:X11 first, then run start-gnome-x11 again." >&2
    exit 1
  fi

  DISPLAY=":${socket#X}"
fi
export DISPLAY

XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
export XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS

if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
  echo "Cannot connect to Termux:X11 display $DISPLAY." >&2
  exit 1
fi

width="$(
  xrandr --display "$DISPLAY" --current \
    | sed -n 's/.*current \([0-9][0-9]*\) x [0-9][0-9]*.*/\1/p' \
    | head -n 1
)"

scale="${GNOME_SCALE:-}"
if [[ -z "$scale" ]]; then
  if [[ -n "$width" ]] && (( width >= 1800 )); then
    scale=2
  else
    scale=1
  fi
fi

if [[ "$scale" != 1 && "$scale" != 2 ]]; then
  echo "GNOME_SCALE must be either 1 or 2." >&2
  exit 2
fi

text_scale="${GNOME_TEXT_SCALE:-1.0}"
dpi=$((96 * scale))

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=gnome-flashback-metacity
export XDG_CURRENT_DESKTOP=GNOME-Flashback:GNOME
export GDK_BACKEND=x11
export GDK_SCALE="$scale"
export QT_QPA_PLATFORM=xcb
export QT_SCALE_FACTOR="$scale"
export XCURSOR_SIZE="$((24 * scale))"

xrandr --display "$DISPLAY" --dpi "$dpi" || true

apply_gnome_scale() {
  gsettings set org.gnome.desktop.interface scaling-factor "$scale"
  gsettings set org.gnome.desktop.interface text-scaling-factor "$text_scale"
  gsettings set org.gnome.desktop.interface cursor-size "$((24 * scale))"
  gsettings set org.gnome.desktop.screensaver lock-enabled false
  gsettings set org.gnome.desktop.session idle-delay 0
}

apply_gnome_scale

systemctl --user import-environment \
  DBUS_SESSION_BUS_ADDRESS \
  DISPLAY \
  GDK_BACKEND \
  GDK_SCALE \
  QT_QPA_PLATFORM \
  QT_SCALE_FACTOR \
  XCURSOR_SIZE \
  XDG_CURRENT_DESKTOP \
  XDG_CONFIG_DIRS \
  XDG_DATA_DIRS \
  XDG_MENU_PREFIX \
  XDG_RUNTIME_DIR \
  XDG_SESSION_DESKTOP \
  XDG_SESSION_TYPE

dbus-update-activation-environment --systemd \
  DBUS_SESSION_BUS_ADDRESS \
  DISPLAY \
  GDK_BACKEND \
  GDK_SCALE \
  QT_QPA_PLATFORM \
  QT_SCALE_FACTOR \
  XCURSOR_SIZE \
  XDG_CURRENT_DESKTOP \
  XDG_CONFIG_DIRS \
  XDG_DATA_DIRS \
  XDG_MENU_PREFIX \
  XDG_RUNTIME_DIR \
  XDG_SESSION_DESKTOP \
  XDG_SESSION_TYPE

# GNOME settings services initialize asynchronously and can replace interface
# defaults once during startup. Reapply the chosen values after they are ready.
(
  sleep 3
  apply_gnome_scale
) &

echo "Starting GNOME Flashback on $DISPLAY (${width:-unknown}px wide, scale ${scale}x, ${dpi} DPI)."
exec gnome-session --session=gnome-flashback-metacity
