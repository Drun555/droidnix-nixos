{ config, pkgs, ... }:

{
  # Deployment context:
  # - NixOS runs as a container inside DroidSpaces, not on bare metal.
  # - DroidSpaces runs on a OnePlus Pad 3 tablet whose host uses WildKernel.
  # The host remains responsible for hardware, boot, kernel, and networking.
  imports = [
    ./droidspaces-base.nix
    ./agent-bootstrap.nix
  ];
}
