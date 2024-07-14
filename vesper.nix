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
    lix
    man
    mosh
    nix-output-monitor
    nixfmt-rfc-style
    nixpkgs-review
    openssh
    pstree
    ripgrep
    uutils-coreutils-noprefix
    vim
  ];
}
