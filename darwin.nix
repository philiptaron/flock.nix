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
    h
    jq
    lima
    man
    nix-output-monitor
    nix-update
    nixfmt-rfc-style
    nixpkgs-review
    nixVersions.latest
    openssh
    powerline-go
    pstree
    ripgrep
    tailscale
    uutils-coreutils-noprefix
    vim
  ];
}
