{
  description = "NixOS configuration for the droidnix DroidSpaces container";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/c6e5ca3c836a5f4dd9af9f2c1fc1c38f0fac988a";

  outputs =
    { nixpkgs, ... }:
    {
      nixosConfigurations.droidnix = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ ./configuration.nix ];
      };
    };
}
