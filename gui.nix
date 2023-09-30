{ config, pkgs, inputs, ... }:

{
  services.xserver = {
    enable = true;
    updateDbusEnvironment = true;

    videoDrivers = [ "nvidia" ];

    # See `nixos/modules/services/x11/xserver.nix` and the list of included packages.
    excludePackages = [ pkgs.xterm ];

    # Enable the GNOME Desktop Environment (not minimal)
    desktopManager.gnome.enable = true;

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

  # Add glib to the set of runnable programs.
  environment.systemPackages = [ pkgs.glib ];

  # Enable the GNOME settings daemon
  services.gnome.gnome-settings-daemon.enable = true;

  # Enable the GNOME keyring
  services.gnome.gnome-keyring.enable = true;

  # Enable gsettings-schemas discovery
  environment.pathsToLink = [ "/share/gsettings-schemas" ];

  services.udev.packages = with pkgs.gnome; [
    # Force enable KMS modifiers for devices that require them.
    # https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/1443
    mutter
  ];

  # Turn on dconf setting. Super minimal.
  programs.dconf.enable = true;
}
