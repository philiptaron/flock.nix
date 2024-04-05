{
  description = "Philip Taron's flock of Nix configuration(s)";
  nixConfig.commit-lockfile-summary = "flake.nix: update the lockfile";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.systems.url = "github:nix-systems/default";

  outputs =
    {
      self,
      nixpkgs,
      systems,
    }:
    let
      inherit (nixpkgs.lib) foldl' recursiveUpdate;

      mkConfig = system: {
        inherit system;

        overlays = [ self.overlays.default ];

        config.allowUnfree = true;
        config.hostPlatform = system;
        config.cudaSupport = true;
        config.nvidia.acceptLicense = true;
      };

      systemClosure =
        attrs: foldl' (acc: system: recursiveUpdate acc (attrs system)) { } (import systems);
    in
    systemClosure (system: {
      # Use the RFC 0166 formatter for this repository
      formatter.${system} = self.legacyPackages.${system}.nixfmt-rfc-style;

      # Evaluate the set of packages available here just once.
      legacyPackages.${system} = import nixpkgs (mkConfig system);
    })
    // {
      overlays = {
        default = import ./overlays.nix;
      };

      nixosConfigurations.zebul = self.legacyPackages.x86_64-linux.callPackage ./zebul.nix {
        inherit (nixpkgs.lib) nixosSystem;
        nixpkgsConnection = {
          nix.registry.nixpkgs.flake = nixpkgs;
        };
      };
    };
}
