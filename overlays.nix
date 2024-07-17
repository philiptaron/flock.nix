final: prev:

let
  inherit (final.lib) trace filter;

  traceDependencyRemoval =
    name: package: e:
    if e == package then trace "${name} is removing ${package.name}" false else true;

  removeGnomeOnlineAccounts = name: filter (traceDependencyRemoval name prev.gnome-online-accounts);
in

{
  # 2024-07-16
  diffoscope = prev.diffoscope.overrideAttrs (prevAttrs: {
    disabledTests = (prevAttrs.disabledTests or [ ]) ++ [ "test_has_visuals" ];
  });

  git = prev.git.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [
      # Print the previous name of the branch when switching it.
      patches/git/0001-checkout-print-previous-branch-name-when-switching.patch
    ];

    # We violate the expectations somehow by changing the message.
    preInstallCheck =
      prevAttrs.preInstallCheck
      + ''
        disable_test t2024-checkout-dwim
      '';
  });

  # Use `nom` in nixos-rebuild
  nixos-rebuild = prev.nixos-rebuild.overrideAttrs (prevAttrs: {
    src = final.applyPatches {
      name = "replace-nix-with-nom";
      src = prevAttrs.src;
      unpackPhase = "install $src ./nixos-rebuild.sh";
      installPhase = "cp ./nixos-rebuild.sh $out";
      patches = [
        (final.substituteAll {
          src = patches/nixos-rebuild/nom-for-nix.patch;
          nixBuild = "${final.nix-output-monitor}/bin/nom-build";
          nixCommand = "${final.nix-output-monitor}/bin/nom";
        })
      ];
    };
  });

  # Include the `--print-build-logs` flag when calling `nix build`.
  nixpkgs-review = prev.nixpkgs-review.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [ patches/nixpkgs-review/print-build-logs.patch ];
  });

  disable-for-gnome-46 = {
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
  };

  # On zebul, we use CUDA 12.3
  cudaPackages = final.cudaPackages_12_3;
}
