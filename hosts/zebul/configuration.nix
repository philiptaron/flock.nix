{ flake, perSystem, ... }:

{
  networking.hostName = "zebul";
  system.stateVersion = "23.05";

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config = {
    allowAliases = false;
    allowUnfree = true;
    cudaSupport = true;
    warnUndeclaredOptions = true;
  };

  imports = [
    # Reusable modules from modules/nixos/
    flake.modules.nixos.bash
    flake.modules.nixos.fonts
    flake.modules.nixos.git
    flake.modules.nixos.kernel-debug
    flake.modules.nixos.nix
    flake.modules.nixos.sound
    flake.modules.nixos.ssh
    flake.modules.nixos.virtualization

    # Zebul-specific modules
    ./boot.nix
    ./containers.nix
    ./gnome.nix
    ./hardware.nix
    ./kernel/default.nix
    ./network.nix
    ./nix.nix
    ./programs.nix
    ./tpm2.nix
  ];
}
