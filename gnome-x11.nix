{ lib, pkgs, ... }:

let
  gnomeTermuxSession = pkgs.writeShellApplication {
    name = "gnome-termux-x11-session";
    runtimeInputs = with pkgs; [
      coreutils
      dbus
      findutils
      glib
      gnugrep
      gnused
      gnome-session
      systemd
      xdpyinfo
      xrandr
    ];
    text = builtins.readFile ./scripts/gnome-termux-x11-session.sh;
  };

  startGnome = pkgs.writeShellApplication {
    name = "start-gnome-x11";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd
    ];
    text = ''
      profile_user="''${USER:-$(id -un)}"
      export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$profile_user/bin:$PATH"
      export XDG_CONFIG_DIRS="/etc/xdg:/run/current-system/sw/etc/xdg''${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}"
      export XDG_DATA_DIRS="/run/current-system/sw/share:/etc/profiles/per-user/$profile_user/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
      export XDG_MENU_PREFIX="gnome-flashback-"

      systemctl --user import-environment \
        DBUS_SESSION_BUS_ADDRESS \
        GI_TYPELIB_PATH \
        LD_LIBRARY_PATH \
        NIX_GSETTINGS_OVERRIDES_DIR \
        PATH \
        PULSE_SERVER \
        XDG_CONFIG_DIRS \
        XDG_DATA_DIRS \
        XDG_MENU_PREFIX \
        XDG_RUNTIME_DIR 2>/dev/null || true

      systemctl --user restart gnome-termux-x11.service
      sleep 1

      if ! systemctl --user is-active --quiet gnome-termux-x11.service; then
        journalctl --user -u gnome-termux-x11.service --no-pager -n 20
        exit 1
      fi

      systemctl --user --no-pager --full status gnome-termux-x11.service
    '';
  };

  stopGnome = pkgs.writeShellApplication {
    name = "stop-gnome-x11";
    runtimeInputs = [ pkgs.systemd ];
    text = "systemctl --user stop gnome-termux-x11.service";
  };
in
{
  # GNOME Shell 49+ is Wayland-only. Flashback with Metacity is the supported
  # GNOME session that can use the X server supplied by Termux:X11.
  services.desktopManager.gnome.flashback.enableMetacity = true;

  # Termux:X11 is the X server. Do not start GDM or a second Xorg server in the
  # DroidSpaces container.
  services.displayManager.gdm.enable = false;
  services.xserver.enable = false;

  # Android/DroidSpaces owns these host-level facilities.
  networking.networkmanager.enable = lib.mkForce false;
  hardware.bluetooth.enable = lib.mkForce false;
  powerManagement.enable = lib.mkForce false;
  services.avahi.enable = lib.mkForce false;
  services.geoclue2.enable = lib.mkForce false;
  services.gnome.gnome-initial-setup.enable = lib.mkForce false;
  services.gnome.gnome-remote-desktop.enable = lib.mkForce false;
  services.gnome.gnome-user-share.enable = lib.mkForce false;
  services.gnome.rygel.enable = lib.mkForce false;
  services.hardware.bolt.enable = lib.mkForce false;
  services.power-profiles-daemon.enable = lib.mkForce false;

  # Mesa 26.1 in nixpkgs includes the KGSL backend used by
  # Turnip/Freedreno on Qualcomm Adreno GPUs.
  hardware.graphics.enable = true;
  environment.variables = {
    MESA_LOADER_DRIVER_OVERRIDE = "kgsl";
    TU_DEBUG = "noconform";
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [ "vivaldi" ];

  # Android already provides the outer device lock screen. A locked GNOME
  # screen is not useful here because the declarative agent account has no
  # local password by default.
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/screensaver".lock-enabled = false;
        "org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 0;
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    firefox
    ghostty
    gnomeTermuxSession
    lite-xl
    mesa-demos
    nautilus
    pulseaudio
    startGnome
    stopGnome
    telegram-desktop
    vivaldi
    vscodium
    vulkan-tools
    xterm
  ];

  # Keep graphical applications visible in the GNOME menu, including icons
  # supplied by packages outside the GNOME module.
  environment.pathsToLink = [
    "/share/applications"
    "/share/icons"
  ];

  xdg.mime.defaultApplications = {
    "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    "x-scheme-handler/file" = [ "org.gnome.Nautilus.desktop" ];
  };

  systemd.user.services.gnome-termux-x11 = {
    description = "GNOME Flashback session on Termux:X11";
    after = [ "dbus.socket" ];
    wants = [ "dbus.socket" ];
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      Type = "simple";
      ExecStart = lib.getExe gnomeTermuxSession;
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # A lingering user manager watches for the Android-owned X11 socket, so
  # opening Termux:X11 is enough to start the GNOME session.
  systemd.user.paths.gnome-termux-x11 = {
    description = "Watch for the Termux:X11 socket";
    wantedBy = [ "default.target" ];
    pathConfig = {
      PathExists = "/tmp/.X11-unix/X5";
      Unit = "gnome-termux-x11.service";
    };
  };
}
