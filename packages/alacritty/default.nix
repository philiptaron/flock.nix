{ pkgs, ... }:

pkgs.alacritty.overrideAttrs (prevAttrs: {
  # See nixos/nixpkgs#22652 for this workaround
  postInstall = (prevAttrs.postInstall or "") + ''
    wrapProgram $out/bin/alacritty --set XCURSOR_THEME Adwaita
  '';
})
