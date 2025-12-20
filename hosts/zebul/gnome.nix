{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    updateDbusEnvironment = true;

    # See `nixos/modules/services/x11/xserver.nix` and the list of included packages.
    excludePackages = [ pkgs.xterm ];

    # Configure keymap in X11
    xkb.layout = "us";
    xkb.variant = "";
  };

  services.displayManager = {
    # Enable the GNOME display manager (gdm).
    gdm.enable = true;

    # We occasionally have problems, and having logs beforehand is really nice.
    gdm.debug = true;

    # Enable the GNOME Desktop Environment (minimal!)
    sessionPackages = [ pkgs.gnome-session.sessions ];
  };

  # Turn on GNOME systemd packages
  systemd.packages = [
    pkgs.gnome-session
    pkgs.gnome-shell
  ];

  environment.systemPackages = with pkgs; [
    # The GNOME shell is the core GNOME package
    gnome-shell

    # The logs for GNOME
    gnome-logs

    # GNOME's Bluetooth agent
    gnome-bluetooth
  ];

  # Most of GNOME uses dconf, and this is the hook to NixOS.
  programs.dconf.enable = true;

  # Use GVFS to provide SMB and NFS mounting in GNOME (plus Trash)
  services.gvfs.enable = true;

  # Enable the GNOME keyring
  services.gnome.gnome-keyring.enable = true;

  # Enable the GCR SSH agent.
  services.gnome.gcr-ssh-agent.enable = true;

  # Enable discovery of GNOME stuff. We'll try to get a smaller hammer over time.
  # Ideally, each different extension should end up adding its own thing here, I think.
  environment.pathsToLink = [ "/share" ];

  services.udev.packages = with pkgs; [
    # Force enable KMS modifiers for devices that require them.
    # https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/1443
    mutter
  ];

  # Various customizations of GNOME.
  users.users.philip.packages = with pkgs; [
    # `authenticator` is a TOTP application for GNOME.
    # https://apps.gnome.org/Authenticator/
    authenticator

    # `dconf-editor` is a GSettings editor for GNOME.
    # https://wiki.gnome.org/Apps/DconfEditor
    dconf-editor

    # `gnome-calculator` solves mathematical equations
    # https://wiki.gnome.org/Apps/Calculator
    gnome-calculator

    # `gnome-calendar` is a simple and beautiful calendar application.
    # https://wiki.gnome.org/Apps/Calendar
    gnome-calendar

    # `gnome-control-center` allows controlling settings in the GNOME desktop
    # https://gitlab.gnome.org/GNOME/gnome-control-center
    gnome-control-center

    # `gnome-font-viewer` does what it says on the tin: it views fonts.
    # https://gitlab.gnome.org/GNOME/gnome-font-viewer
    gnome-font-viewer

    # `gnome-sound-recorder` is a simple and modern sound recorder.
    # https://wiki.gnome.org/Apps/SoundRecorder
    gnome-sound-recorder

    # Utility used in the GNOME desktop environment for taking screenshots
    # https://gitlab.gnome.org/GNOME/gnome-screenshot
    gnome-screenshot

    # `nautilus` is the file manager for GNOME. It's also known as "Files".
    # https://apps.gnome.org/Nautilus/
    nautilus

    # `seahorse` is an application for managing encryption keys and passwords in the GNOME keyring.
    # https://wiki.gnome.org/Apps/Seahorse
    seahorse

    # A simple app icon taskbar. Show running apps and favorites on the main panel.
    # https://extensions.gnome.org/extension/4944/app-icons-taskbar/
    gnomeExtensions.app-icons-taskbar

    # Adds a clock to the desktop.
    # https://extensions.gnome.org/extension/5156/desktop-clock/
    gnomeExtensions.desktop-clock

    # `gnome-connections` is a remote desktop client for the GNOME desktop environment.
    # https://gitlab.gnome.org/GNOME/connections
    gnome-connections

    # `loupe` is a simple image viewer application written with GTK4 and Rust.
    # https://gitlab.gnome.org/GNOME/loupe
    loupe
  ];

  # Enable XDG portal support
  xdg.portal.enable = true;
  xdg.portal.configPackages = [ pkgs.gnome-session ];
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-gnome
    pkgs.xdg-desktop-portal-gtk
  ];

}
