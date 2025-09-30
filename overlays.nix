final: prev:

let
  inherit (final.lib) trace filter;

  traceDependencyRemoval =
    name: package: e:
    if e == package then trace "${name} is removing ${package.name}" false else true;
in

{
  # Include the `--print-build-logs` flag when calling `nix build`.
  nixpkgs-review = prev.nixpkgs-review.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [ patches/nixpkgs-review/print-build-logs.patch ];
  });

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
