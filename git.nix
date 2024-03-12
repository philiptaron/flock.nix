{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  specialArgs,
}:

let
  gitConfig = pkgs.substituteAll {
    src = dotfiles/git/config;
    sshkey = dotfiles/ssh/personal_id_ed25519.pub;
  };
in

{
  # `git` is a distributed version control system.
  # https://git-scm.com/
  programs.git.enable = true;

  # `git-lfs` is used to distribute large files with Git.
  # https://git-lfs.github.com/
  programs.git.lfs.enable = true;

  # Land the git config in the right spot.
  systemd.user.tmpfiles.users.philip.rules = [ "L+ %h/.config/git/config - - - - ${gitConfig}" ];
}
