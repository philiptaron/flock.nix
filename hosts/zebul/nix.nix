{ ... }:

{
  # Let's try having a small set of build machines.
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "selene.tail0e0e4.ts.net";
      protocol = "ssh-ng";
      system = "x86_64-darwin";
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
