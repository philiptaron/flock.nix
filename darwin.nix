# This is a poor man's `nix-darwin`.
# Install with `nix profile install github:philiptaron/flock.nix#vesper`
# You might need to clear out all other installed items.
{ pkgs, symlinkJoin }:

symlinkJoin {
  name = "darwin";

  # I use `callPackage` as a way to avoid having with statements or prefix everything with `pkgs.`
  paths = pkgs.callPackage ./darwin-packages.nix { };
}
