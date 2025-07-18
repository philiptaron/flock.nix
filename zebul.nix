{
  pkgs,
  nixosSystem,
  system,
}:

nixosSystem {
  inherit pkgs;

  modules = [
    { networking.hostName = "zebul"; }
    { system.stateVersion = "23.05"; }
    ./bash.nix
    ./boot.nix
    ./containers.nix
    ./git.nix
    ./gnome.nix
    # ./labwc.nix
    ./fonts.nix
    ./hardware.nix
    ./kernel/default.nix
    ./network.nix
    ./nix.nix
    ./programs.nix
    ./sound.nix
  ];
}
