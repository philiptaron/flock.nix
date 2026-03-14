{ pkgs, perSystem, ... }:

let
  nix-eval-jobs = pkgs.nix-eval-jobs.override {
    nixComponents = perSystem.self.nix.libs;
  };
in

assert pkgs.lib.assertMsg (
  -1 == builtins.compareVersions nix-eval-jobs.version "2.34.0"
) "Update `packages/nix-eval-jobs/default.nix` now that a new release of nix-eval-jobs is out.";

nix-eval-jobs.overrideAttrs {
  version = "2.34.1-unstable-2026-03-12";
  src = pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nix-eval-jobs";
    rev = "65ebf5b7cd453a27af09cf02b1fc57b3568cc4b7";
    hash = "sha256-OFGRoJOYhvZ3Enk5a8vMy0QNcG5ZxyzFhyHMrwKXde8=";
  };
}
