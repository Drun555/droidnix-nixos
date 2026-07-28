# droidnix

NixOS configuration for the `droidnix` environment.

## Deployment context

- NixOS runs as a container inside DroidSpaces; it is not a bare-metal NixOS installation.
- DroidSpaces is running on a OnePlus Pad 3 tablet.
- The tablet's host system uses WildKernel.

The Android/DroidSpaces host owns the device hardware, boot process, kernel, and
network setup. Changes to this repository should preserve the container-specific
assumptions documented in `agent-bootstrap.nix`.

## GNOME through Termux:X11

GNOME Shell in this NixOS release is Wayland-only, so the X11 desktop uses GNOME
Flashback with Metacity. Termux:X11 supplies the X server; the container does not
start GDM or its own Xorg server.

Start Termux:X11 first, then run this inside `droidnix`:

```console
start-gnome-x11
```

The launcher detects the active display socket. It uses scale `1` below 1800
pixels of display width and scale `2` at higher resolutions, which is suitable
for the OnePlus Pad 3 native display. Override it when needed:

```console
GNOME_SCALE=2 start-gnome-x11
stop-gnome-x11
```

The nested GNOME session does not lock itself or blank on idle because Android
provides the outer device lock screen.

The desktop includes COSMIC Files, Firefox, Lite XL, VSCodium, and Telegram
Desktop. COSMIC Files is the default file manager. Lite XL is the lightweight
editor, while VSCodium provides a larger IDE-style environment without
Microsoft's proprietary distribution. Their desktop entries and icons are
linked into the GNOME application menu.
