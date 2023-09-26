{
  description = "Philip Taron's configuration(s)";

  inputs = {
    empty.url = "path:./empty.nix";
    empty.flake = false;
    nixpkgs.url = "github:NixOS/nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    # Stub these out so that they don't do anything.
    agenix.inputs.darwin.follows = "empty";
    agenix.inputs.home-manager.follows = "empty";
  };

  outputs = { self, nixpkgs, agenix, ... }@inputs:
    let
      hostname = "zebul";
      system = "x86_64-linux";
    in
    {
      overlays.default = final: prev: {
      };
      formatter."${system}" = nixpkgs.legacyPackages."${system}".nixpkgs-fmt;
      nixosModules = {
        programs.agenix = agenix.nixosModules.default;
        traits.overlay = { nixpkgs.overlays = [ self.overlays.default ]; };
      };
      nixosConfigurations."${hostname}" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = with self.nixosModules; [
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
          programs.agenix
        ];
      };
    };
}
