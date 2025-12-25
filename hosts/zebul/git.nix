{ pkgs, perSystem, ... }:

let
  dotfiles = perSystem.self.dotfiles;
in

{
  # `git` is a distributed version control system.
  # https://git-scm.com/
  programs.git.enable = true;

  programs.git.package = pkgs.git.override {
    withLibsecret = true;
  };

  # `git-lfs` is used to distribute large files with Git.
  # https://git-lfs.github.com/
  programs.git.lfs.enable = true;

  # Land the git config in the right spot.
  systemd.user.tmpfiles.users.philip.rules = [
    "L+ %h/.config/git/config - - - - ${dotfiles}/gitconfig"
  ];
}
