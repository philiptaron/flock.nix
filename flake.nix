{
  description = "Philip Taron's flock of Nix configuration(s)";
  nixConfig.commit-lockfile-summary = "flake.nix: update the lockfile";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs?ref=pull/379731/merge";

  outputs =
    { self, nixpkgs, ... }:
    let
      mkConfig = system: {
        inherit system;

        overlays = [ self.overlays.default ];

        config.allowUnfree = true;
        config.cudaSupport = true;
        config.warnUndeclaredOptions = true;
      };

      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      # Evaluate the set of packages available here just once.
      packages = eachSystem (system: import nixpkgs (mkConfig system));

      eachSystem = f: nixpkgs.lib.genAttrs systems f;
    in
    {
      # Use the RFC 0166 formatter for this repository
      formatter = eachSystem (system: packages.${system}.nixfmt-rfc-style);

      # We're making `nix-darwin` with spit and bailing wire.
      packages.x86_64-darwin.darwin = packages.x86_64-darwin.callPackage ./darwin.nix { };
      packages.aarch64-darwin.darwin = packages.aarch64-darwin.callPackage ./darwin.nix { };

      # The overlay for substituting a few things.
      overlays.default = import ./overlays.nix;

      # My main NixOS machine.
      nixosConfigurations.zebul = packages.x86_64-linux.callPackage ./zebul.nix {
        inherit (nixpkgs.lib) nixosSystem;
      };
    };
}
