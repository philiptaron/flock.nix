# `h`, with a wrapper per identity baked in.
#
# The shell functions from `h-shell-init` carry the root, the store and the git identity
# themselves, but scripts, hooks and agents run the binary, which reads them from $H_CODE_ROOT,
# $H_STORE and $H_GIT_OPTS. `.override { identities = …; }` wraps it once per identity, under the
# identity's name: `hq = { root = "~/Qumulo"; store = …; gitOpts = …; }` makes `bin/hq`.
# `--set-default` means an explicit variable in the environment still wins. A program no identity
# is named after (`h-shell-init`, `up`, `up-shell-init`, and `h` itself if need be) comes through
# unchanged.
{
  pkgs,
  perSystem,
  identities ? import ./identities.nix,
  ...
}:

let
  inherit (pkgs) lib;
  h = perSystem.h.default;

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
    for program in h h-shell-init up up-shell-init; do
      [ -e $out/bin/$program ] || ln -s ${h}/bin/$program $out/bin/$program
    done
  ''
