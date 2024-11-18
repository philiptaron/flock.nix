{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  specialArgs,
}:

# Make the fonts look better.
# TODO: make Chinese and other East Asian characters display in Firefox.
{
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
}
