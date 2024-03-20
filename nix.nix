{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  specialArgs,
}:

{
  # I like living on the edge.
  nix.package = pkgs.nixVersions.unstable;

  # Let's try having a small set of build machines.
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "selene.tail0e0e4.ts.net";
      protocol = "ssh-ng";
      system = "x86_64-darwin";
      sshKey = "/nix/var/keys/id_selene";
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUVkek9kZFRFeEdXc3l3MnpaTHl3MVJBVkRCL2svV1J1bHo0TFhlKy82b3MgCg==";
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

  environment.systemPackages = with pkgs; [
    # `nixdoc` is used to generate reference documentation for functions defined in Nixpkgs' lib.
    # https://github.com/nix-community/nixdoc/
    nixdoc

    # `nix-doc` helps navigating nixpkgs and other Nix code.
    # https://github.com/lf-/nix-doc
    nix-doc

    # `nix-output-monitor` is a fancy shell that makes nix-build much prettier.
    # https://github.com/maralorn/nix-output-monitor
    nix-output-monitor

    # Interactively browse a Nix store paths dependencies
    # https://hackage.haskell.org/package/nix-tree
    nix-tree

    # A files database for nixpkgs
    # https://github.com/nix-community/nix-index
    nix-index

    # `nixfmt` is the work-in-progress RFC 166 linter.
    # https://github.com/piegamesde/nixfmt/tree/rfc101-style
    nixfmt-rfc-style
  ];
}
