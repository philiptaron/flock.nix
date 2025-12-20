{ pkgs, ... }:

pkgs.hyperfine.overrideAttrs {
  # Patch to switch to not using a shell by default. Breaks the tests.
  patches = [ ../../patches/hyperfine/no-shell-by-default.patch ];
  doCheck = false;
}
