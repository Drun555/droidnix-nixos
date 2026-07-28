# droidnix

NixOS configuration for the `droidnix` environment.

## Deployment context

- NixOS runs as a container inside DroidSpaces; it is not a bare-metal NixOS installation.
- DroidSpaces is running on a OnePlus Pad 3 tablet.
- The tablet's host system uses WildKernel.

The Android/DroidSpaces host owns the device hardware, boot process, kernel, and
network setup. Changes to this repository should preserve the container-specific
assumptions documented in `agent-bootstrap.nix`.

Set the container's Init field in DroidSpaces to:

```text
/sbin/droidspaces-nixos-init
```

This regular wrapper file is maintained by NixOS activation and starts the
current `/nix/var/nix/profiles/system/init` from inside the container. Do not
point DroidSpaces directly at the system profile: its absolute symlink cannot be
resolved correctly while DroidSpaces validates it from the Android host.

## GNOME through Termux:X11

GNOME Shell in this NixOS release is Wayland-only, so the X11 desktop uses GNOME
Flashback with Metacity. Termux:X11 supplies the X server; the container does not
start GDM or its own Xorg server.

Opening Termux:X11 automatically starts the GNOME session when its X11 socket
appears. The launcher remains available for manual restarts:

```console
start-gnome-x11
```

The launcher detects the active display socket. Its tablet-friendly default is
125%: integer application scale `1`, text and Qt scale `1.25`, and 120 DPI.
Override it when needed:

```console
GNOME_SCALE=2 start-gnome-x11
GNOME_TEXT_SCALE=1.0 GNOME_DPI=96 start-gnome-x11
stop-gnome-x11
```

The nested GNOME session does not lock itself or blank on idle because Android
provides the outer device lock screen.

The desktop includes GNOME Files (Nautilus), Firefox, Vivaldi, Lite XL,
VSCodium, Telegram Desktop, and Ghostty. GNOME Files is the default file
manager. Lite XL is the lightweight editor, while VSCodium provides a larger
IDE-style environment without Microsoft's proprietary distribution. Their
desktop entries and icons are linked into the GNOME application menu.

## Native Adreno graphics and Android audio

The OnePlus Pad 3 exposes an Adreno 830 GPU as `/dev/kgsl-3d0`. The configuration
pins the Android-container-patched Mesa/Turnip release
`26.2.0-devel-20260709` from
[Mesa For Android Container](https://github.com/lfdevs/mesa-for-android-container).
The `agent` user belongs to the `droidspaces-gpu` group, and the GNOME launcher
selects its KGSL, EGL, and Vulkan drivers explicitly.

In the DroidSpaces container settings:

- enable **GPU Access** and **Configure Termux:X11**;
- disable **Configure VirGL 3D Acceleration**;
- enable **Configure PulseAudio**.

DroidSpaces supplies the X11 and PulseAudio sockets. The NixOS configuration
installs `glxinfo`, `vulkaninfo`, `pactl`, `paplay`, and a test sound theme for
verification. It does not start a second PulseAudio server inside the container.
