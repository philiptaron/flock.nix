{ config, pkgs, inputs, ... }:

{
  services.xserver = {
    enable = false;
    updateDbusEnvironment = true;

    # See `nixos/modules/services/x11/xserver.nix` and the list of included packages.
    excludePackages = [ pkgs.xterm ];

    # Enable the GNOME Desktop Environment (minimal!)
    displayManager.sessionPackages = with pkgs.gnome; [
      gnome-session.sessions
    ];

    # Enable the GNOME display manager (gdm) and turn Wayland on!
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };

    # Configure keymap in X11
    layout = "us";
    xkbVariant = "";
  };

  # Make the fonts look better
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

  environment.systemPackages = with pkgs; [
    # GLib provides the core building blocks for libraries and applications written in C.
    # It provides the core object system used in GNOME, the main loop implementation, and a large
    # set of utility functions for strings and common data structures.
    # https://wiki.gnome.org/Projects/GLib
    glib

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
  ];

  # Enable the GNOME keyring
  services.gnome.gnome-keyring.enable = true;

  # Enable discovery of GNOME stuff. We'll try to get a smaller hammer over time.
  # Ideally, each different extension should end up adding its own thing here, I think.
  environment.pathsToLink = [ "/share" ];

  services.udev.packages = with pkgs; [
    # Force enable KMS modifiers for devices that require them.
    # https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/1443
    gnome.mutter
  ];

  # Various customizations of GNOME.
  users.users.philip.packages = with pkgs; [
    # `dconf-editor` is a GSettings editor for GNOME.
    # https://wiki.gnome.org/Apps/DconfEditor
    gnome.dconf-editor

    # `gnome-sound-recorder` is a simple and modern sound recorder.
    # https://wiki.gnome.org/Apps/SoundRecorder
    gnome.gnome-sound-recorder

    # Utility used in the GNOME desktop environment for taking screenshots
    # https://gitlab.gnome.org/GNOME/gnome-screenshot
    gnome.gnome-screenshot

    # A simple app icon taskbar. Show running apps and favorites on the main panel.
    # https://extensions.gnome.org/extension/4944/app-icons-taskbar/
    gnomeExtensions.app-icons-taskbar

    # Adds a clock to the desktop.
    # https://extensions.gnome.org/extension/5156/desktop-clock/
    gnomeExtensions.desktop-clock

    # Move clock to left of status menu button
    # https://extensions.gnome.org/extension/2/move-clock/
    gnomeExtensions.move-clock

    # Allows the customization of the date format on the GNOME panel.
    # https://extensions.gnome.org/extension/3465/panel-date-format/
    gnomeExtensions.panel-date-format-2
  ];

  # Turn on dconf setting. Super minimal.
  programs.dconf.enable = true;
}
