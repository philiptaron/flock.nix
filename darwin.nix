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
    lix
    man
    nix-output-monitor
    nix-update
    nixfmt-rfc-style
    nixpkgs-review
    openssh
    pstree
    ripgrep
    tailscale
    uutils-coreutils-noprefix
    vim
  ];
}
