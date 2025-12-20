{ pkgs, perSystem, ... }:

pkgs.nixpkgs-review.override {
  nix = perSystem.self.nix;
  withNom = true;
}
