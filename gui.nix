{ config, pkgs, inputs, ... }:

{
  services.xserver = {
    enable = true;

    #videoDrivers = [ "nvidia" ];

    # See `nixos/modules/services/x11/xserver.nix` and the list of included packages.
    excludePackages = [ pkgs.xterm ];

    # Enable the GNOME Desktop Environment (minimal!)
    displayManager.gdm.enable = true;
    displayManager.sessionPackages = with pkgs.gnome; [
      gnome-session.sessions
    ];

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

  # Turn on dconf setting. Super minimal.
  programs.dconf.enable = true;
}
