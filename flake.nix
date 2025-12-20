{
  description = "Philip Taron's flock of Nix configuration(s)";
  nixConfig.commit-lockfile-summary = "flake.nix: update the lockfile";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs =
    { self, nixpkgs, ... }:
    let
      mkConfig = system: {
        inherit system;

        # Aliases aren't allowed in Nixpkgs, and they often herald changes that need attention.
        # Rather than silently continuing to eval, I'd prefer to see the breaks up front.
        config.allowAliases = false;

        # Unlike Nixpkgs, I have no qualms with using and working with unfree software.
        config.allowUnfree = true;

        # Zebul has an NVIDIA 3090 TI and CUDA makes it powerful.
        config.cudaSupport = builtins.match ".*-linux" system != null;

        # If we do use undeclared options, let's make it known.
        config.warnUndeclaredOptions = true;

        # Use the packages directory as an overlay.
        overlays = [ (import ./packages/default.nix) ];
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

      # My main NixOS machine.
      nixosConfigurations.zebul = packages.x86_64-linux.callPackage ./zebul.nix {
        inherit (nixpkgs.lib) nixosSystem;
        system = "x86_64-linux";
      };
    };
}
