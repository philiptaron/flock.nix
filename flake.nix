{
  description = "Philip Taron's configuration(s)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";

    # Empty flake for making complex flake dependencies stop dead.
    empty.url = "path:./empty.nix";
    empty.flake = false;

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.darwin.follows = "empty";
    agenix.inputs.home-manager.follows = "empty";

    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    fh.inputs.nixpkgs.follows = "nixpkgs";

    llama-cpp.url = "github:ggerganov/llama.cpp";
    llama-cpp.inputs.nixpkgs.follows = "nixpkgs";

    nurl.url = "github:nix-community/nurl";
    nurl.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{self, nixpkgs, ...}: let
    overlays' = {
      default = import ./overlays.nix;
      agenix = inputs.agenix.overlays.default;
      fh = inputs.fh.overlays.default;
      nurl = inputs.nurl.overlays.default;
    };
    config = {
      allowUnfree = true;
    };
    overlays = builtins.attrValues overlays';
    x86_64-linux = import nixpkgs {
      inherit config overlays;
      system = "x86_64-linux";
    };
    aarch64-darwin = import nixpkgs {
      inherit config overlays;
      system = "aarch64-darwin";
    };
    aarch64-linux = import nixpkgs {
      inherit config overlays;
      system = "aarch64-linux";
    };
  in
  {
    overlays = overlays';
    nixosConfigurations.zebul = nixpkgs.lib.nixosSystem {
      pkgs = x86_64-linux;
      inherit (x86_64-linux) system;
      modules = [
        { networking.hostName = "zebul"; }
        { system.stateVersion = "23.05"; }
        { nix.registry.nixpkgs.flake = inputs.nixpkgs; }
        ./boot.nix
        ./containers.nix
        ./gui.nix
        ./hardware.nix
        ./network.nix
        ./nix.nix
        ./programs.nix
        ./sound.nix
        ./virtualization.nix
      ];
    };
  };
}
