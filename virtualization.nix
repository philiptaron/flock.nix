{ pkgs, ... }:

{
  # Use Podman as a Docker standin
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerSocket.enable = true;
  environment.systemPackages = with pkgs; [ docker-client ];
}
