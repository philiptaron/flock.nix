{ htop }:

htop.overrideAttrs (prevAttrs: {
  # Remove the .desktop icon; no need to launch htop from Gnome.
  postInstall = (prevAttrs.postInstall or "") + ''
    rm -rf $out/share/{applications,icons,pixmaps}
  '';
})
