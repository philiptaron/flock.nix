{
  description = "Philip Taron's configuration(s)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, agenix }@inputs: let
    hostname = "zebul";
    system = "x86_64-linux";
  in {
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
        agenix.nixosModules.default
      ];
    };
  };
}
