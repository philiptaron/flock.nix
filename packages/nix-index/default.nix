{ pkgs, perSystem, ... }:

pkgs.nix-index.override {
  nix = perSystem.self.nix;
}
