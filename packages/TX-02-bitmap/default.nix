{ pkgs, ... }:

# TX-02 bitmap fonts (CP437, 8 pixels wide)
pkgs.stdenvNoCC.mkDerivation {
  pname = "TX-02-bitmap";
  version = "1.0.0";

  src = pkgs.fetchurl {
    url = "https://gist.githubusercontent.com/philiptaron/31d7692feb76e948e245ed3d4e40a3ba/raw/b4dcf224c1977b3678d4d88519a4f6e2c82b255d/TX-02-bitmap.zip.b64";
    hash = "sha256-cDhjp19PICzkh+ze5KNG2jrqzUTjzTvzEeUEnT8h7QI=";
  };

  nativeBuildInputs = [ pkgs.unzip ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out
    base64 -d $src > fonts.zip
    unzip -j fonts.zip -d $out
  '';
}
