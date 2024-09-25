{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  specialArgs,
}:

{
  services.xserver = {
    enable = true;
    updateDbusEnvironment = true;

    # See `nixos/modules/services/x11/xserver.nix` and the list of included packages.
    excludePackages = [ pkgs.xterm ];

    # Enable the GNOME display manager (gdm).
    displayManager.gdm.enable = true;
    displayManager.gdm.debug = true;

    # Configure keymap in X11
    xkb.layout = "us";
    xkb.variant = "";
  };

  # Enable the GNOME Desktop Environment (minimal!)
  services.displayManager.sessionPackages = [ pkgs.gnome-session.sessions ];

  # Make both gdm and my user session use the same `monitors.xml` file.
  # This is specific to zebul, and will eventually be split out.
  systemd.tmpfiles.rules = [
    "L+ /run/gdm/.config/monitors.xml - - - - ${dotfiles/gnome/monitors.xml}"
  ];

  systemd.user.tmpfiles.users.philip.rules = [
    "L+ %h/.config/monitors.xml - - - - ${dotfiles/gnome/monitors.xml}"
  ];

  # Make the fonts look better.
  fonts = {
    enableDefaultPackages = false;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      cantarell-fonts
    ];

    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "Noto Sans Mono" ];
    };
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

    # Small utility to dump info about DRM devices.
    # https://gitlab.freedesktop.org/emersion/drm_info
    drm_info

    # Test utilities for OpenGL
    # https://dri.freedesktop.org/wiki/glxinfo/
    glxinfo

    # Tool for reading and parsing EDID data from monitors
    # http://www.polypux.org/projects/read-edid/
    read-edid

    # EDID decoder and conformance tester
    # https://git.linuxtv.org/edid-decode.git
    edid-decode

    # Provides the `vkcube`, `vkcubepp`, `vkcube-wayland`, and `vulkaninfo` tools.
    # https://github.com/KhronosGroup/Vulkan-Tools
    vulkan-tools
  ];

  # Most of GNOME uses dconf, and this is the hook to NixOS.
  programs.dconf.enable = true;

  # Use GVFS to provide SMB and NFS mounting in GNOME (plus Trash)
  services.gvfs.enable = true;

  # Enable the GNOME keyring
  services.gnome.gnome-keyring.enable = true;

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

    # `zulip` is the desktop client for Zulip chat.
    # https://zulip.com/
    zulip
  ];

  # Enable XDG portal support
  xdg.portal.enable = true;
  xdg.portal.configPackages = [ pkgs.gnome-session ];
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-gnome
    (pkgs.xdg-desktop-portal-gtk.override {
      # Do not build portals that we already have.
      buildPortalsInGnome = false;
    })
  ];

  # Try out flatpak
  services.flatpak.enable = true;
}
