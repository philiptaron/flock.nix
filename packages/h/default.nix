# `h` and `hq`: the h tool with each identity's code root, object store and git identity baked in.
#
# The shell functions from the bashrc carry the root, the store and the git identity themselves,
# but scripts, hooks and agents run the binary, which reads them from $H_CODE_ROOT, $H_STORE and
# $H_GIT_OPTS. So this package wraps it once per identity in ./identities.nix: `h` defaults to
# the personal one, `hq` to the Qumulo one. `--set-default` means an explicit variable in the
# environment still wins. The other programs (`h-shell-init`, `up`, `up-shell-init`) come through
# unchanged.
{ pkgs, perSystem, ... }:

let
  inherit (pkgs) lib;
  h = perSystem.h.default;
  identities = import ./identities.nix;

  wrap = name: identity: ''
    makeWrapper ${h}/bin/h $out/bin/${name} \
      --set-default H_CODE_ROOT ${lib.escapeShellArg identity.root} \
      --set-default H_STORE ${lib.escapeShellArg identity.store} \
      --set-default H_GIT_OPTS ${lib.escapeShellArg identity.gitOpts}
  '';
in
pkgs.runCommand "h-wrapped-${h.version}"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    inherit (h) version meta;
    passthru.unwrapped = h;
  }
  ''
    mkdir -p $out/bin
    ${lib.concatStrings (lib.mapAttrsToList wrap identities)}
    for program in h-shell-init up up-shell-init; do
      ln -s ${h}/bin/$program $out/bin/$program
    done
  ''
