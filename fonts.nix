{ config, pkgs, ... }:

# We're all in on Google's `noto` (NO TOfu) fonts.
{
  fonts = {
    enableDefaultPackages = false;
    packages = [
      pkgs.noto-fonts
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-cjk-serif
      pkgs.noto-fonts-color-emoji
      pkgs.noto-fonts-monochrome-emoji
      pkgs.cantarell-fonts
    ];

    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "Noto Sans Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
