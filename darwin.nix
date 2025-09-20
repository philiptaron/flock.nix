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

    (hyperfine.overrideAttrs {
      # Patch to switch to not using a shell by default. Breaks the tests.
      patches = [ patches/hyperfine/no-shell-by-default.patch ];
      doCheck = false;
    })

    jq
    lima

    # Our select set of LLM plugins.
    (callPackage ./llm.nix { })

    man
    nix-output-monitor
    nix-update
    nixVersions.git
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
