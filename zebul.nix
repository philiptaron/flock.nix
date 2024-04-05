{
  pkgs,
  nixosSystem,
  nixpkgsConnection,
}:

nixosSystem {
  inherit pkgs;
  inherit (pkgs) system;

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
}
