{ pkgs, ... }:

pkgs.btop-cuda.overrideAttrs (prevAttrs: {
  # Remove the .desktop icon; no need to launch btop from Gnome.
  postInstall = (prevAttrs.postInstall or "") + ''
    rm -rf $out/share/{applications,icons}
  '';
})
