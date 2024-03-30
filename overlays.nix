final: prev:

let
  traceDependencyRemoval =
    name: package: e:
    if e == package then builtins.trace "${name} is removing ${package.name}" false else true;

  removeGnomeOnlineAccounts =
    name: builtins.filter (traceDependencyRemoval name prev.gnome-online-accounts);
in

{
  # Include the `--print-build-logs` flag when calling `nix build`.
  nixpkgs-review = prev.nixpkgs-review.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [ patches/nixpkgs-review/print-build-logs.patch ];
  });

  # Enable building Evolution Data Server without Gnome Online Accounts (GOA)
  evolution-data-server = prev.evolution-data-server.overrideAttrs (prevAttrs: {
    buildInputs = removeGnomeOnlineAccounts "evolution-data-server" prevAttrs.buildInputs;
    cmakeFlags = [ "-DENABLE_GOA=OFF" ] ++ prevAttrs.cmakeFlags;
  });

  gnome = prev.gnome.overrideScope (
    gnome-final: gnome-prev: {
      # Enable building Gnome Control Center without Gnome Online Accounts (GOA)
      gnome-control-center = gnome-prev.gnome-control-center.overrideAttrs (prevAttrs: {
        buildInputs = removeGnomeOnlineAccounts "gnome-control-center" prevAttrs.buildInputs;
        patches = prevAttrs.patches ++ [ patches/gnome-control-center/remove-gnome-online-accounts.patch ];
      });

      # Enable building GNOME VFS without Gnome Online Accounts (GOA)
      gvfs = gnome-prev.gvfs.overrideAttrs (prevAttrs: {
        buildInputs = removeGnomeOnlineAccounts "gvfs" prevAttrs.buildInputs;
        mesonFlags = prevAttrs.mesonFlags ++ [
          "-Dgoa=false"
          "-Dgoogle=false"
        ];
      });
    }
  );

  libgdata = prev.libgdata.overrideAttrs (prevAttrs: {
    propagatedBuildInputs = removeGnomeOnlineAccounts "libgdata" prevAttrs.propagatedBuildInputs;
    mesonFlags = prevAttrs.mesonFlags ++ [ "-Dgoa=disabled" ];
  });

  # On zebul, we use CUDA 12.3
  cudaPackages = final.cudaPackages_12_3;
}
