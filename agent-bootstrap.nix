{ lib, pkgs, ... }:

{
  boot.isContainer = true;
  system.stateVersion = "26.05";

  networking = {
    hostName = "droidnix";

    # DroidSpaces/Android already owns the network configuration.
    useDHCP = lib.mkForce false;

    # Android's netfilter implementation is incompatible with the
    # default NixOS nftables-based firewall in this container.
    firewall.enable = lib.mkForce false;
  };

  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    openFirewall = true;
    startWhenNeeded = false;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "agent" ];
    };
  };

  users.groups = {
    aid_inet.gid = 3003;
    aid_net_raw.gid = 3004;
    aid_net_admin.gid = 3005;
  };

  # Android gates Internet access by supplementary group. Nix fixed-output
  # derivations fetch upstream sources as nixbld users, so they need aid_inet.
  users.users =
    (lib.genAttrs
      (map (number: "nixbld${toString number}") (lib.range 1 32))
      (_: {
        extraGroups = [ "aid_inet" ];
      }))
    // {
      root.extraGroups = [
        "aid_inet"
        "aid_net_raw"
        "aid_net_admin"
      ];

      agent = {
        isNormalUser = true;
        description = "NixOS configuration agent";
        extraGroups = [
          "wheel"
          "aid_inet"
          "aid_net_raw"
          "aid_net_admin"
        ];
        shell = pkgs.bashInteractive;

        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTJ5Iue9uAgEcimByfd5PrzkuG55o2uKqpXzdLDxPdBKYdPJffoxtzuD/2AB6Yc6t0DDGSV9hjphZSL/IDUWLipEPdxdOa6+ITWo56y8N1JkxZ4fv0X7we5u5gqzZ45BKyOUQmo1na/RmChlzypAOVWgC+/rmejOn5il2xZjWxcink1CFTTyX1RYaEyagQSJYDMhDB0FUgg1uxyOkGcdqNIFBPG/jc5+1hJGk67Cynih5kY3oS9V7cuNEmv3u36HDSM/JPF23wQteIx7jp75txRhfqGgbovTpu/9iS7FaoIrpkHnkJfRl5luPzH8cbrGm55X8knKDX2dAw6Tr1ccrF drun@DrunPC"
        ];
      };
    };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  
  nix.settings.sandbox = false;
  environment.localBinInPath = true;

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    jq
    ripgrep
    fd
    tree
    tmux
    nano
    vim
    openssh
  ];
}
