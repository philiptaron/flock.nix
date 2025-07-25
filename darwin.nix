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
    lima

    # Our select set of LLM plugins.
    (pkgs.callPackage ./llm.nix { })

    man
    nix-output-monitor
    nix-update
    nixfmt
    nixpkgs-review
    nixVersions.nix_2_30
    openssh
    q
    powerline-go
    pstree
    ripgrep
    tailscale
    uutils-coreutils-noprefix
    vim
  ];
}
