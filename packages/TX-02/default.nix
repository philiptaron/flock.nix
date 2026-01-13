{ pkgs, ... }:

# TX-02 TrueType fonts
pkgs.stdenvNoCC.mkDerivation {
  pname = "TX-02";
  version = "1.0.0";

  src = pkgs.fetchurl {
    url = "https://gist.githubusercontent.com/philiptaron/31d7692feb76e948e245ed3d4e40a3ba/raw/77d13d22a024047bc90a6f5a4bef62896db7c3ce/TX-02.zip.b64";
    hash = "sha256-0yyc4wJr+FZZ0CAVFBl5cKmMDFkCR7FbNPlT5zMEkz0=";
  };

  nativeBuildInputs = [ pkgs.unzip ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    base64 -d $src > fonts.zip
    unzip -j fonts.zip -d $out/share/fonts/truetype
  '';
}
