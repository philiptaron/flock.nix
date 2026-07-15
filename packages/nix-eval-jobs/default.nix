{ pkgs, perSystem, ... }:

# nixpkgs' nix-eval-jobs (2.34.3) fails to compile against Nix 2.35, which
# removed saveMountNamespace(). Pull the source from PR #427 (which swaps it for
# tryEnterPrivateMountNamespace) until it merges and lands in nixpkgs.
# https://github.com/NixOS/nix-eval-jobs/pull/427
(pkgs.nix-eval-jobs.override {
  nixComponents = perSystem.self.nix.libs;
}).overrideAttrs
  (old: {
    src = pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nix-eval-jobs";
      rev = "e918d76daa1417b48578354e2c845f1c162e49e3"; # branch update-nix-2.35 / PR #427
      hash = "sha256-5+yojVc9xzEAEji8fQX5mivc96kpqoAbQx6Kxt3VK4c=";
    };
  })
