{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  specialArgs,
  _class,
}:

let
  bashrc = pkgs.replaceVars dotfiles/bash/bashrc {
    # `h` is a tool to check out and jump to checked-out repositories.
    # https://github.com/zimbatm/h
    inherit (pkgs) h;

    # `git` is just Git!
    git = config.programs.git.package;
  };
in

{
  # Give a bashrc that's worth a damn.
  programs.bash.interactiveShellInit = "source ${bashrc}";

  # Don't turn on colors through `LS_COLORS` environment variable.
  programs.bash.enableLsColors = false;

  # Set up inputrc to be my custom one.
  environment.etc.inputrc.source = dotfiles/readline/inputrc;
}
