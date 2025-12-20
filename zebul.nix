{
  nixosSystem,
  system,
}:

nixosSystem {
  modules = [
    { networking.hostName = "zebul"; }
    { system.stateVersion = "23.05"; }
    {
      nixpkgs.hostPlatform = system;
      nixpkgs.config = {
        allowAliases = false;
        allowUnfree = true;
        cudaSupport = true;
        warnUndeclaredOptions = true;
      };
      nixpkgs.overlays = [ (import ./packages/default.nix) ];
    }
    ./bash.nix
    ./boot.nix
    ./containers.nix
    ./git.nix
    ./gnome.nix
    ./fonts.nix
    ./hardware.nix
    ./kernel/default.nix
    ./network.nix
    ./nix.nix
    ./programs.nix
    ./sound.nix
    ./virtualization.nix
  ];
}
