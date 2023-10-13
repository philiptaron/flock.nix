final: prev:

{
  # Enable building Evolution Data Server without Gnome Online Accounts (GOA)
  evolution-data-server = prev.evolution-data-server.overrideAttrs (prevAttrs: {
    buildInputs = builtins.filter (e: e != prev.gnome-online-accounts) prevAttrs.buildInputs;
    cmakeFlags = [ "-DENABLE_GOA=OFF" ] ++ prevAttrs.cmakeFlags;
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

  # Try to turn on developer mode for iwd
  iwd = prev.iwd.overrideAttrs (prevAttrs: {
    preFixup = prevAttrs.preFixup + ''
      sed -i -e "s,ExecStart.*,\0 -E," $out/lib/systemd/system/iwd.service
    '';
  });
}
