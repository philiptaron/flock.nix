{ pkgs, perSystem, ... }:

pkgs.nix-update.override {
  nix = perSystem.self.nix;
}
