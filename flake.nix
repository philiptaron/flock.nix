{
  description = "Philip Taron's configuration(s)";

  inputs = {
    flake-compat.url = "github:nix-community/flake-compat";
    systems.url = "github:nix-systems/x86_64-linux";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    nixpkgs.url = "github:NixOS/nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, systems, flake-utils, nixpkgs, agenix, ... }@inputs:
    let
      hostname = "zebul";
      system = "x86_64-linux";
    in
    {
      formatter."${system}" = nixpkgs.legacyPackages."${system}".nixpkgs-fmt;
      nixosConfigurations."${hostname}" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          { networking.hostName = hostname; }
          { nixpkgs.hostPlatform = system; }
          { nixpkgs.config.allowUnfree = true; }
          { system.stateVersion = "23.05"; }
          ./boot.nix
          ./containers.nix
          ./gui.nix
          ./hardware.nix
          ./nix.nix
          ./programs.nix
          ./sound.nix
          agenix.nixosModules.default
        ];
      };
    };
}
