{ ... }:

{
  # Let's try having a small set of build machines.
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "selene.tail0e0e4.ts.net";
      protocol = "ssh-ng";
      system = "x86_64-darwin";
      # Tailscale SSH's host key, SHA256:w5sugelKr/DuzK45V6xOjBsDREUPac8OoBaRoJssIRg.
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSU9pbWtuUzdFTTNXSEgreC9wSWJMNUNJU3NyUDZsb3FLZ09SMDkrSGR4MFQ=";
    }
    {
      hostName = "vesper.tail0e0e4.ts.net";
      protocol = "ssh-ng";
      system = "aarch64-darwin";
    }
  ];

  # Allow the Nix daemon's environment to be configured from a normal (root-owned) file.
  systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "/etc/nixos/nix-daemon-environment";
}
