# droidnix

NixOS configuration for the `droidnix` environment.

## Deployment context

- NixOS runs as a container inside DroidSpaces; it is not a bare-metal NixOS installation.
- DroidSpaces is running on a OnePlus Pad 3 tablet.
- The tablet's host system uses WildKernel.

The Android/DroidSpaces host owns the device hardware, boot process, kernel, and
network setup. Changes to this repository should preserve the container-specific
assumptions documented in `agent-bootstrap.nix`.
