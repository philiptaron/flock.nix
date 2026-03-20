{ pkgs, perSystem, ... }:

pkgs.nix-eval-jobs.override {
  nixComponents = perSystem.self.nix.libs;
}
