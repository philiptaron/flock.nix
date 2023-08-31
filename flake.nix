{
  description = "Philip Taron's configuration(s)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, agenix }@inputs: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    nixosConfigurations.zebul = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.config.allowUnfree = true; }
        ./flake-configuration.nix
        agenix.nixosModules.default
      ];
    };
  };
}
