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

  outputs = inputs@{self, nixpkgs, ...}: {
    overlays = {
      default = import ./overlays.nix;
    };

    nixosModules = {
      traits.overlay = {
        nixpkgs.overlays = [
          self.overlays.default
          inputs.agenix.overlays.default
          inputs.fh.overlays.default
          inputs.nurl.overlays.default
        ];
      };
    };

    nixosConfigurations.zebul = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = with self.nixosModules; [
        { networking.hostName = "zebul"; }
        { nixpkgs.hostPlatform = "x86_64-linux"; }
        { nixpkgs.config.allowUnfree = true; }
        { system.stateVersion = "23.05"; }
        ./boot.nix
        ./containers.nix
        ./gui.nix
        ./hardware.nix
        ./network.nix
        ./nix.nix
        ./programs.nix
        ./sound.nix
        traits.overlay
      ];
    };
  };
}
