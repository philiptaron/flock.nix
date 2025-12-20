{ pkgs, perSystem, ... }:

pkgs.nurl.override {
  nix = perSystem.self.nix;
}
