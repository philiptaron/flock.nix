# This is a poor man's `nix-darwin`.
# Install with `nix profile install github:philiptaron/flock.nix#vesper`
# You might need to clear out all other installed items.
{
  symlinkJoin,

  bash-completion,
  bashInteractive,
  bat,
  cacert,
  fd,
  findutils,
  gh,
  git,
  h,
  jq,
  man,
  mosh,
  nix-output-monitor,
  nixpkgs-review,
  nixVersions,
  openssh,
  pstree,
  ripgrep,
  vim,
  uutils-coreutils-noprefix,
}:

symlinkJoin {
  name = "vesper";
  paths = [
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
    nixVersions.latest
    openssh
    pstree
    ripgrep
    vim
    uutils-coreutils-noprefix
  ];
}
