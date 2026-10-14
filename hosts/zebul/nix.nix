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
    {
      # Shared work box (80-core Ampere, NixOS); keep our share of it modest.
      hostName = "smarm1.eng.qumulo.com";
      protocol = "ssh-ng";
      system = "aarch64-linux";
      sshUser = "philip";
      sshKey = "/home/philip/.ssh/qumulo_id_ed25519";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [
        "benchmark"
        "big-parallel"
        "kvm"
        "nixos-test"
        "gccarch-armv8-a"
      ];
      # SHA256:NI1Cz8gOaxlClfV/bLZdAPwXxvd4taH6nRh2cynNJUw.
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUp0R0l1cmlqMHhseVRSQmNadHdoU0o1WldxSGtwUWRlNnZQcVZUTnlhbkE=";
    }
  ];

  # Allow the Nix daemon's environment to be configured from a normal (root-owned) file.
  systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "/etc/nixos/nix-daemon-environment";
}
