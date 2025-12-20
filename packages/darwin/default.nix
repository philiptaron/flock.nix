# This is a poor man's `nix-darwin`.
# Install with `nix profile install github:philiptaron/flock.nix#darwin`
# You might need to clear out all other installed items.
{ pkgs, perSystem, ... }:

pkgs.symlinkJoin {
  name = "darwin";

  # I use `callPackage` as a way to avoid having with statements or prefix everything with `pkgs.`
  paths = pkgs.callPackage ./packages.nix {
    philiptaron = {
      hyperfine = perSystem.self.hyperfine;
      llm = perSystem.self.llm;
      nix = perSystem.self.nix;
      nix-diff = perSystem.self.nix-diff;
      nix-doc = perSystem.self.nix-doc;
      nix-index = perSystem.self.nix-index;
      nix-update = perSystem.self.nix-update;
      nixpkgs-review = perSystem.self.nixpkgs-review;
    };
  };
}
