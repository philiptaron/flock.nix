{
  description = "Philip Taron's flock of Nix configuration(s)";
  nixConfig.commit-lockfile-summary = "flake.nix: update the lockfile";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs =
    { self, nixpkgs }:
    let
      overlays = {
        default = import ./overlays.nix;
      };

      mkConfig = system: {
        inherit system;

        overlays = builtins.attrValues overlays;

        config.allowUnfree = true;
        config.hostPlatform = system;
        config.cudaSupport = true;
        config.nvidia.acceptLicense = true;
      };

      x86_64-linux = import nixpkgs (mkConfig "x86_64-linux");
      aarch64-darwin = import nixpkgs (mkConfig "aarch64-darwin");
      aarch64-linux = import nixpkgs (mkConfig "aarch64-linux");
      nixpkgsConnection = {
        nix.registry.nixpkgs.flake = nixpkgs;
      };
    in
    {
      inherit overlays;

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      nixosConfigurations.zebul = nixpkgs.lib.nixosSystem {
        pkgs = x86_64-linux;
        inherit (x86_64-linux) system;
        modules = [
          { networking.hostName = "zebul"; }
          { system.stateVersion = "23.05"; }
          nixpkgsConnection
          ./boot.nix
          ./containers.nix
          ./git.nix
          ./gui.nix
          ./hardware.nix
          ./kernel/default.nix
          ./network.nix
          ./nix.nix
          ./programs.nix
          ./sound.nix
        ];
      };
    };
}
