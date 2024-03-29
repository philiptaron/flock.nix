final: prev:

let
  inherit (final.lib) trace filter;

  traceDependencyRemoval =
    name: package: e:
    if e == package then trace "${name} is removing ${package.name}" false else true;

  removeGnomeOnlineAccounts =
    name: filter (traceDependencyRemoval name prev.gnome-online-accounts);

  gitMinimal = prev.git.override {
    withManual = false;
    perlSupport = false;
    pythonSupport = false;
    withLibsecret = false;
  };
in

{
  # Build `git` with fewer dependencies, but //with// libsecret by default.
  git = prev.git.override {
    perlSupport = false;
    pythonSupport = false;
    withLibsecret = true;
  };

  # Avoid a circular dependency with `libsecret`
  fetchgit = prev.fetchgit.override {
    git = gitMinimal;
  };

  # TODO: make this the default?
  libselinux = prev.libselinux.override {
    enablePython = false;
  };

  # TODO: add in `withManual` to allow libtiff to build without docs.
  libtiff = prev.libtiff.overrideAttrs (prevAttrs: {
    outputs = filter (name: !(name == "man" || name == "doc")) prevAttrs.outputs;
    nativeBuildInputs = [ final.autoreconfHook final.pkg-config ];
  });

  # TODO: how many packages depend on `buildPackages.gitMinimal`?
  makeRustPlatform = prev.makeRustPlatform.override {
    buildPackages = prev.buildPackages // { inherit gitMinimal; };
  };

  # Include the `--print-build-logs` flag when calling `nix build`.
  nixpkgs-review = prev.nixpkgs-review.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [ ./nixpkgs-review-print-build-logs.patch ];
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
        patches = prevAttrs.patches ++ [ ./remove-online-accounts-from-gnome-control-center.patch ];
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
