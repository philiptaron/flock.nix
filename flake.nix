{
  description = "Philip Taron's flock of Nix configuration(s)";
  nixConfig.commit-lockfile-summary = "flake.nix: update the lockfile";

  inputs.nixpkgs.url = "github:philiptaron/nixpkgs/nikstur/systemd-256";

  outputs =
    { self, nixpkgs, ... }:
    let
      mkConfig = system: {
        inherit system;

        overlays = [ self.overlays.default ];

        config.allowUnfree = true;
        config.hostPlatform = system;
        config.cudaSupport = true;
        config.nvidia.acceptLicense = true;
      };

      # Until https://github.com/NixOS/nixpkgs/pull/295083 is accepted and merged.
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      eachSystem = f: nixpkgs.lib.genAttrs systems f;
    in
    {
      # Use the RFC 0166 formatter for this repository
      formatter = eachSystem (system: self.legacyPackages.${system}.nixfmt-rfc-style);

      # Evaluate the set of packages available here just once.
      legacyPackages = eachSystem (system: import nixpkgs (mkConfig system));

      packages.aarch64-darwin.vesper = self.legacyPackages.aarch64-darwin.callPackage ./vesper.nix { };

      overlays = {
        default = import ./overlays.nix;
      };

      # My main NixOS machine.
      nixosConfigurations.zebul = self.legacyPackages.x86_64-linux.callPackage ./zebul.nix {
        inherit (nixpkgs.lib) nixosSystem;
        nixpkgsConnection = {
          nix.registry.nixpkgs.flake = nixpkgs;
        };
      };
    };
}
