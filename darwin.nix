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
    # and forward the SSH agent into the guest.
    (lima.overrideAttrs (prevAttrs: {
      patches = (prevAttrs.patches or [ ]) ++ [ patches/lima/ssh.patch ];
    }))

    (llm.withPlugins {
      llm-anthropic = true;
      llm-gemini = true;
      llm-grok = true;
      llm-openai-plugin = true;
      llm-cmd = true;
      llm-tools-quickjs = true;
      llm-tools-simpleeval = true;
      llm-tools-sqlite = true;
      llm-fragments-github = true;
    })

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
