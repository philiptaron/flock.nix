{ config, lib, modulesPath, options, pkgs, specialArgs }:

{
  nix.package = pkgs.nixFlakes;
  nix.settings.experimental-features = [
    # Enable the new nix subcommands. See the manual on nix for details.
    # https://nixos.org/manual/nix/unstable/contributing/experimental-features#xp-feature-nix-command
    "nix-command"

    # Enable flakes. See the manual entry for nix flake for details.
    # https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake
    "flakes"

    # Allow the use of a few things related to dynamic derivations:
    #  * "text hashing" derivation outputs, so we can build .drv files.
    #  *  dependencies in derivations on the outputs of derivations that are themselves
    #     derivations outputs.
    # https://nixos.org/manual/nix/unstable/contributing/experimental-features#xp-feature-dynamic-derivations
    "dynamic-derivations"

    # Allow derivations to be content-addressed in order to prevent rebuilds when changes to the
    # derivation do not result in changes to the derivation's output.
    # https://nixos.org/manual/nix/unstable/language/advanced-attributes#adv-attr-__contentAddressed
    "ca-derivations"

    # Allow passing installables to `nix repl`, making its interface consistent with the other
    # experimental commands.
    # https://nixos.org/manual/nix/unstable/contributing/experimental-features#xp-feature-repl-flake
    "repl-flake"
  ];

  environment.systemPackages = with pkgs; [
    # Interactively browse a Nix store paths dependencies
    # https://hackage.haskell.org/package/nix-tree
    nix-tree

    # A files database for nixpkgs
    # https://github.com/nix-community/nix-index
    nix-index
  ];
}
