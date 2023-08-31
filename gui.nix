{ config, pkgs, inputs, ... }:

{
  services.xserver = {
    enable = true;

    videoDrivers = [ "nvidia" ];

    # Enable the GNOME Desktop Environment (minimal!)
    displayManager.gdm.enable = true;
    displayManager.sessionPackages = [ pkgs.gnome.gnome-session.sessions ];

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
