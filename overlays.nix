final: prev:

let
  removeGnomeOnlineAccounts = builtins.filter (e: e != prev.gnome-online-accounts);
  removeGtk2 = builtins.filter (e: e != prev.gtk2);
in

{
  # Include the `--print-build-logs` flag when calling `nix build`.
  nixpkgs-review = prev.nixpkgs-review.overrideAttrs (prevAttrs: {
    patches = (if prevAttrs ? patches then prevAttrs.patches else []) ++ [
      ./nixpkgs-review-print-build-logs.patch
    ];
  });

  # Enable building Evolution Data Server without Gnome Online Accounts (GOA)
  evolution-data-server = prev.evolution-data-server.overrideAttrs (prevAttrs: {
    buildInputs = removeGnomeOnlineAccounts prevAttrs.buildInputs;
    cmakeFlags = [ "-DENABLE_GOA=OFF" ] ++ prevAttrs.cmakeFlags;
  });

  ibus = prev.ibus.overrideAttrs (prevAttrs: {
    buildInputs = removeGtk2 prevAttrs.buildInputs;
    configureFlags = [ "--disable-gtk2" ] ++ prevAttrs.configureFlags;
  });

  gnome = prev.gnome.overrideScope' (gnome-final: gnome-prev: {
    # Enable building Gnome Control Center without Gnome Online Accounts (GOA)
    gnome-control-center = gnome-prev.gnome-control-center.overrideAttrs (prevAttrs: {
      buildInputs = removeGnomeOnlineAccounts prevAttrs.buildInputs;
      patches = prevAttrs.patches ++ [ ./remove-online-accounts-from-gnome-control-center.patch ];
    });

    # Enable building GNOME VFS without Gnome Online Accounts (GOA)
    gvfs = gnome-prev.gvfs.overrideAttrs (prevAttrs: {
      buildInputs = removeGnomeOnlineAccounts prevAttrs.buildInputs;
      mesonFlags = prevAttrs.mesonFlags ++ [ "-Dgoa=false" "-Dgoogle=false" ];
    });
  });

  # Work in progress: build wpa_supplicant from source
  #wpa_supplicant = prev.wpa_supplicant.overrideAttrs (prevAttrs: {
  #  src = prev.fetchgit {
  #    url = "git://w1.fi/hostap.git";
  #    rev = "7629ac4deff7a006702de8d3df00ae2f8119cafa";
  #    hash = "sha256-uZLRSw4wXX3NfINAtC9bhZY5qO3wE5v8BczkBq4KIt8=";
  #  };
  #  patches = [];
  #});
}
