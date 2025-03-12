# This is a poor man's `nix-darwin`.
# Install with `nix profile install github:philiptaron/flock.nix#vesper`
# You might need to clear out all other installed items.
{ pkgs, symlinkJoin }:

symlinkJoin {
  name = "darwin";
  paths = with pkgs; [
    bash-completion
    bashInteractive
    bat
    cacert
    fd
    findutils
    gh
    git
    gping
    h
    jq

    # Remove the annoying message of command-line line 0: Unsupported option "gssapiauthentication"
    (lima.overrideAttrs (prevAttrs: {
      patches = (prevAttrs.patches or [ ]) ++ [ patches/lima/GSSAPIAuthentication.patch ];
    }))

    man
    nix-output-monitor
    nix-update
    nixfmt-rfc-style
    nixpkgs-review
    nixVersions.nix_2_26
    openssh
    powerline-go
    pstree
    ripgrep
    tailscale
    uutils-coreutils-noprefix
    vim
  ];
}
