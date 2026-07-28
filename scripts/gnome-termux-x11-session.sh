set -euo pipefail

if [[ -r /run/droidspaces.env ]]; then
  # DroidSpaces injects DISPLAY and the host PulseAudio socket here.
  # shellcheck disable=SC1091
  source /run/droidspaces.env
fi

profile_user="${USER:-$(id -un)}"
export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$profile_user/bin:$PATH"
export XDG_CONFIG_DIRS="/etc/xdg:/run/current-system/sw/etc/xdg${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}"
export XDG_DATA_DIRS="/run/current-system/sw/share:/etc/profiles/per-user/$profile_user/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
export XDG_MENU_PREFIX="gnome-flashback-"
export MESA_LOADER_DRIVER_OVERRIDE=kgsl
export TU_DEBUG=noconform
export LIBGL_DRIVERS_PATH="@mesaForAndroidLib@/dri"
export __EGL_VENDOR_LIBRARY_FILENAMES="@mesaForAndroidEgl@"
export VK_ICD_FILENAMES="@mesaForAndroidVulkan@"
unset GALLIUM_DRIVER

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

scale="${GNOME_SCALE:-1}"

if [[ "$scale" != 1 && "$scale" != 2 ]]; then
  echo "GNOME_SCALE must be either 1 or 2." >&2
  exit 2
fi

text_scale="${GNOME_TEXT_SCALE:-1.25}"
dpi="${GNOME_DPI:-120}"

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=gnome-flashback-metacity
export XDG_CURRENT_DESKTOP=GNOME-Flashback:GNOME
export GDK_BACKEND=x11
export GDK_SCALE="$scale"
export QT_QPA_PLATFORM=xcb
export QT_SCALE_FACTOR="${QT_SCALE_FACTOR:-1.25}"
export XCURSOR_SIZE="${XCURSOR_SIZE:-32}"

xrandr --display "$DISPLAY" --dpi "$dpi" || true

apply_gnome_scale() {
  gsettings set org.gnome.desktop.interface scaling-factor "$scale"
  gsettings set org.gnome.desktop.interface text-scaling-factor "$text_scale"
  gsettings set org.gnome.desktop.interface cursor-size "$XCURSOR_SIZE"
  gsettings set org.gnome.desktop.screensaver lock-enabled false
  gsettings set org.gnome.desktop.session idle-delay 0
}

apply_gnome_scale

systemctl --user import-environment \
  DBUS_SESSION_BUS_ADDRESS \
  DISPLAY \
  GDK_BACKEND \
  GDK_SCALE \
  LIBGL_DRIVERS_PATH \
  MESA_LOADER_DRIVER_OVERRIDE \
  PULSE_SERVER \
  QT_QPA_PLATFORM \
  QT_SCALE_FACTOR \
  TU_DEBUG \
  VK_ICD_FILENAMES \
  XCURSOR_SIZE \
  XDG_CURRENT_DESKTOP \
  XDG_CONFIG_DIRS \
  XDG_DATA_DIRS \
  XDG_MENU_PREFIX \
  XDG_RUNTIME_DIR \
  XDG_SESSION_DESKTOP \
  XDG_SESSION_TYPE \
  __EGL_VENDOR_LIBRARY_FILENAMES

dbus-update-activation-environment --systemd \
  DBUS_SESSION_BUS_ADDRESS \
  DISPLAY \
  GDK_BACKEND \
  GDK_SCALE \
  LIBGL_DRIVERS_PATH \
  MESA_LOADER_DRIVER_OVERRIDE \
  PULSE_SERVER \
  QT_QPA_PLATFORM \
  QT_SCALE_FACTOR \
  TU_DEBUG \
  VK_ICD_FILENAMES \
  XCURSOR_SIZE \
  XDG_CURRENT_DESKTOP \
  XDG_CONFIG_DIRS \
  XDG_DATA_DIRS \
  XDG_MENU_PREFIX \
  XDG_RUNTIME_DIR \
  XDG_SESSION_DESKTOP \
  XDG_SESSION_TYPE \
  __EGL_VENDOR_LIBRARY_FILENAMES

# GNOME settings services initialize asynchronously and can replace interface
# defaults once during startup. Reapply the chosen values after they are ready.
(
  sleep 3
  apply_gnome_scale
) &

echo "Starting GNOME Flashback on $DISPLAY (${width:-unknown}px wide, scale ${scale}x, ${dpi} DPI)."
exec gnome-session --session=gnome-flashback-metacity
