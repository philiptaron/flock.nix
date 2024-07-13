# This is a poor man's `nix-darwin`.
# Install with `nix profile install github:philiptaron/flock.nix#vesper`
# You might need to clear out all other installed items.
{ pkgs, symlinkJoin }:

symlinkJoin {
  name = "vesper";
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
    man
    mosh
    nix-output-monitor
    nixpkgs-review
    lix
    openssh
    pstree
    ripgrep
    vim
    uutils-coreutils-noprefix
  ];
}
