# Dotfiles collection - processed config files for various programs.
{ pkgs, ... }:

let
  # Process bashrc with variable substitutions.
  bashrc = pkgs.replaceVars ./bash/bashrc {
    inherit (pkgs) h git;
  };

  # Process git config with ssh key.
  gitconfig = pkgs.replaceVars ./git/config {
    sshkey = ./ssh/personal_id_ed25519.pub;
  };
in
pkgs.runCommand "dotfiles" { } ''
  mkdir -p $out

  # Processed files
  cp ${bashrc} $out/bashrc
  cp ${gitconfig} $out/gitconfig

  # Raw files
  cp ${./alacritty/alacritty.toml} $out/alacritty.toml
  cp ${./gdb/gdbinit} $out/gdbinit
  cp ${./ghostty/config} $out/ghostty
  cp ${./readline/inputrc} $out/inputrc
  cp ${./ssh/personal_id_ed25519.pub} $out/ssh-public-key
  cp ${./Library/LaunchAgents/add-ssh-keys.plist} $out/add-ssh-keys.plist
''
