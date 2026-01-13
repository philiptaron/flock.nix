{ pkgs, ... }:

# TX-02 PSF2 fonts for Linux console (CP437, 8 pixels wide)
pkgs.stdenvNoCC.mkDerivation {
  pname = "TX-02-psf";
  version = "1.0.0";

  src = pkgs.fetchurl {
    url = "https://gist.githubusercontent.com/philiptaron/31d7692feb76e948e245ed3d4e40a3ba/raw/b4dcf224c1977b3678d4d88519a4f6e2c82b255d/TX-02-psf.zip.b64";
    hash = "sha256-5s+VDnXN+NGX/KEZpktMxWax0M6fWTOznznqY7GDLk8=";
  };

  nativeBuildInputs = [ pkgs.unzip ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/consolefonts
    base64 -d $src > fonts.zip
    unzip -j fonts.zip -d $out/share/consolefonts
  '';
}
