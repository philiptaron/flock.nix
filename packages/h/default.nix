# `h` and `hq`: the h tool with each identity's code root and object store baked in.
#
# The shell functions from the bashrc carry the root, the store and the git identity themselves,
# but the bare binary only reads $H_CODE_ROOT and $H_STORE. Scripts, hooks and agents run the
# binary, so this package wraps it twice: `h` defaults to the personal root and store, `hq` to the
# Qumulo ones. `--set-default` means an explicit variable in the environment still wins. The
# other programs (`h-shell-init`, `up`, `up-shell-init`) come through unchanged.
{ pkgs, perSystem, ... }:

let
  h = perSystem.h.default;
in
pkgs.runCommand "h-wrapped-${h.version}"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    inherit (h) version meta;
    passthru.unwrapped = h;
  }
  ''
    mkdir -p $out/bin
    makeWrapper ${h}/bin/h $out/bin/h \
      --set-default H_CODE_ROOT '~/Code' \
      --set-default H_STORE '~/.cache/git/philiptaron'
    makeWrapper ${h}/bin/h $out/bin/hq \
      --set-default H_CODE_ROOT '~/Qumulo' \
      --set-default H_STORE '~/.cache/git/PhilipTaronQ'
    for program in h-shell-init up up-shell-init; do
      ln -s ${h}/bin/$program $out/bin/$program
    done
  ''
