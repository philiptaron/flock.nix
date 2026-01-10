{ config, pkgs, ... }:

let
  TX-02 = pkgs.fetchurl {
    url = "https://gist.githubusercontent.com/philiptaron/31d7692feb76e948e245ed3d4e40a3ba/raw/f7b4714a850ad07c46878e51467f41e34a578569/TX-02.zip.b64";
    hash = "sha256-0yyc4wJr+FZZ0CAVFBl5cKmMDFkCR7FbNPlT5zMEkz0=";

    nativeBuildInputs = [ pkgs.unzip ];

    downloadToTemp = true;

    postFetch = ''
      mkdir -p $out/share/fonts/truetype
      base64 -d $downloadedFile > fonts.zip
      unzip -j fonts.zip -d $out/share/fonts/truetype
    '';
  };
in

# We're all in on Google's `noto` (NO TOfu) fonts.
{
  fonts = {
    enableDefaultPackages = false;
    packages = [
      TX-02
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
