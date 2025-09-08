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
    nixVersions.nix_2_31
    nixfmt
    nixpkgs-review
    openssh
    powerline-go
    pstree
    q
    qrtool
    ripgrep
    tailscale
    uutils-coreutils-noprefix
    vim
  ];
}
