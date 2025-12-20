{ pkgs, perSystem, ... }:

pkgs.nix-doc.override {
  nix = perSystem.self.nix;
}
