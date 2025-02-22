final: prev:

let
  inherit (final.lib) trace filter;

  traceDependencyRemoval =
    name: package: e:
    if e == package then trace "${name} is removing ${package.name}" false else true;
in

{
  # Use `nom` in nixos-rebuild
  nixos-rebuild = prev.nixos-rebuild.overrideAttrs (prevAttrs: {
    src = final.applyPatches {
      name = "replace-nix-with-nom";
      src = prevAttrs.src;
      unpackPhase = "install $src ./nixos-rebuild.sh";
      installPhase = "cp ./nixos-rebuild.sh $out";
      patches = [
        (final.replaceVars patches/nixos-rebuild/nom-for-nix.patch {
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

  # On zebul, we use a driver that can do CUDA 12.6, but this is the latest in nixpkgs.
  cudaPackages = final.cudaPackages_12_4;

  # Minimal shell for use as basic /bin/sh in sandbox builds
  busybox-sandbox-shell = final.busybox.override {
    useMusl = true;
    enableStatic = true;
    enableMinimal = true;

    extraConfig = ''
      CONFIG_FEATURE_FANCY_ECHO y
      CONFIG_FEATURE_SH_MATH y
      CONFIG_FEATURE_SH_MATH_64 y
      CONFIG_FEATURE_TEST_64 y

      CONFIG_MKDIR y
      CONFIG_LN y
      CONFIG_MV y
      CONFIG_CP y

      CONFIG_ASH y
      CONFIG_ASH_OPTIMIZE_FOR_SIZE y

      CONFIG_ASH_ALIAS y
      CONFIG_ASH_BASH_COMPAT y
      CONFIG_ASH_CMDCMD y
      CONFIG_ASH_ECHO y
      CONFIG_ASH_GETOPTS y
      CONFIG_ASH_INTERNAL_GLOB y
      CONFIG_ASH_JOB_CONTROL y
      CONFIG_ASH_PRINTF y
      CONFIG_ASH_TEST y
    '';
  };
}
