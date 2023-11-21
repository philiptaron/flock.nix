{
  description = "Philip Taron's configuration(s)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/gnome";
    empty.url = "path:./empty.nix";
    empty.flake = false;
    systems.url = "github:nix-systems/x86_64-linux";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    fh.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    llama-cpp.url = "github:ggerganov/llama.cpp";
    llama-cpp.inputs.nixpkgs.follows = "nixpkgs";
    llama-cpp.inputs.flake-utils.follows = "flake-utils";

    # Stub these out so that they don't do anything.
    agenix.inputs.darwin.follows = "empty";
    agenix.inputs.home-manager.follows = "empty";
  };

  outputs = inputs@{self, nixpkgs, agenix, systems, ...}: let
    eachSystem = nixpkgs.lib.genAttrs (import systems);
    x86_64-linux = builtins.elemAt (import systems) 0;
  in {
    formatter = eachSystem (system: nixpkgs.legacyPackages."${system}".nixpkgs-fmt);

    overlays = {
      default = import ./overlays.nix;
    };

    nixosModules = {
      programs.agenix = agenix.nixosModules.default;
      traits.overlay = { nixpkgs.overlays = [ self.overlays.default ]; };
    };

    nixosConfigurations.zebul = nixpkgs.lib.nixosSystem {
      system = x86_64-linux;
      specialArgs = {
        inherit inputs;
      };
      modules = with self.nixosModules; [
        { networking.hostName = "zebul"; }
        { nixpkgs.hostPlatform = x86_64-linux; }
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
        programs.agenix
        traits.overlay
      ];
    };
  };
}
