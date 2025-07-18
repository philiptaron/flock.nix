{ pkgs, ... }:

{
  nix.package = pkgs.nixVersions.nix_2_30;

  # We absolutely do not use channels.
  nix.channel.enable = false;

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

  nix.settings.experimental-features = [
    # Enable the new nix subcommands. See the manual on nix for details.
    # https://nixos.org/manual/nix/unstable/contributing/experimental-features#xp-feature-nix-command
    "nix-command"

    # Enable flakes. See the manual entry for nix flake for details.
    # https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake
    "flakes"
  ];

  # Allow the Nix daemon's environment to be configured from a normal (root-owned) file.
  systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "/etc/nixos/nix-daemon-environment";

  environment.systemPackages = with pkgs; [
    # `nixdoc` is used to generate reference documentation for functions defined in Nixpkgs' lib.
    # https://github.com/nix-community/nixdoc/
    nixdoc

    # `nix-bisect` helps bisect failing things in nixpkgs
    # https://github.com/timokau/nix-bisect
    nix-bisect

    # `nix-diff` shows why derivations differ.
    # https://github.com/Gabriella439/nix-diff
    nix-diff

    # `nix-doc` helps navigating nixpkgs and other Nix code.
    # https://github.com/lf-/nix-doc
    nix-doc

    # `nix-eval-jobs` helps use more than one core to get Nix evaluation work done.
    # https://github.com/nix-community/nix-eval-jobs
    nix-eval-jobs

    # `nix-output-monitor` is a fancy shell that makes nix-build much prettier.
    # https://github.com/maralorn/nix-output-monitor
    nix-output-monitor

    # Interactively browse a Nix store paths dependencies
    # https://hackage.haskell.org/package/nix-tree
    nix-tree

    # A files database for nixpkgs
    # https://github.com/nix-community/nix-index
    nix-index

    # A quick way to update packages in `nixpkgs`.
    # https://github.com/Mic92/nix-update
    nix-update

    # `nixfmt` is the official formatter for Nix code in Nixpkgs.
    # https://github.com/NixOS/nixfmt
    nixfmt

    # `nurl` generates Nix fetcher calls from repository URLs
    # https://github.com/nix-community/nurl
    nurl
  ];
}
