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

    philiptaron.hyperfine

    jq
    lima

    # Our select set of LLM plugins.
    philiptaron.llm

    man
    nix-output-monitor
    philiptaron.nix-diff
    philiptaron.nix-doc
    philiptaron.nix-index
    philiptaron.nix-update

    # Our select Nix version and patches
    philiptaron.nix
    nixfmt
    philiptaron.nixpkgs-review
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
