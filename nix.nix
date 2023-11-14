{ config, pkgs, inputs, ... }:

{
  nix = {
    package = pkgs.nixFlakes;
    registry.nixpkgs.flake = inputs.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  environment.systemPackages = with pkgs; [
    # Interactively browse a Nix store paths dependencies
    # https://hackage.haskell.org/package/nix-tree
    nix-tree

    # A files database for nixpkgs
    # https://github.com/nix-community/nix-index
    nix-index
  ];
}
