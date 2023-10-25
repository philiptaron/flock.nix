final: prev:

{
  # Enable building Evolution Data Server without Gnome Online Accounts (GOA)
  evolution-data-server = prev.evolution-data-server.overrideAttrs (prevAttrs: {
    buildInputs = builtins.filter (e: e != prev.gnome-online-accounts) prevAttrs.buildInputs;
    cmakeFlags = [ "-DENABLE_GOA=OFF" ] ++ prevAttrs.cmakeFlags;
  });
  # Until https://github.com/NixOS/nixpkgs/pull/263241 is pulled, imitate it on tip
  frogmouth = prev.frogmouth.overrideAttrs (prevAttrs: {
    postUnpack = ''
      sed -i -e "s,from xdg import,from xdg_base_dirs import," $sourceRoot/frogmouth/data/{config,data_directory}.py
    '';
  });
  ibus = prev.ibus.overrideAttrs (prevAttrs: {
    buildInputs = builtins.filter (e: e != prev.gtk2) prevAttrs.buildInputs;
    configureFlags = [ "--disable-gtk2" ] ++ prevAttrs.configureFlags;
  });
  gnome = prev.gnome.overrideScope' (gnome-final: gnome-prev: {
    # Enable building Gnome Control Center without Gnome Online Accounts (GOA)
    gnome-control-center = gnome-prev.gnome-control-center.overrideAttrs (prevAttrs: {
      buildInputs = builtins.filter (e: e != prev.gnome-online-accounts) prevAttrs.buildInputs;
      patches = prevAttrs.patches ++ [ ./remove-online-accounts-from-gnome-control-center.patch ];
    });
  });
}
