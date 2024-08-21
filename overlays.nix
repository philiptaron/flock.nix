final: prev:

let
  inherit (final.lib) trace filter;

  traceDependencyRemoval =
    name: package: e:
    if e == package then trace "${name} is removing ${package.name}" false else true;
in

{
  # 2024-07-16
  diffoscope = prev.diffoscope.overrideAttrs (prevAttrs: {
    disabledTests = (prevAttrs.disabledTests or [ ]) ++ [ "test_has_visuals" ];
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

  # On zebul, we use CUDA 12.3
  cudaPackages = final.cudaPackages_12_3;
}
