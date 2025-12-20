{ perSystem, ... }:

let
  dotfiles = perSystem.self.dotfiles;
in

{
  # Give a bashrc that's worth a damn.
  programs.bash.interactiveShellInit = "source ${dotfiles}/bashrc";

  # Don't turn on colors through `LS_COLORS` environment variable.
  programs.bash.enableLsColors = false;

  # Set up inputrc to be my custom one.
  environment.etc.inputrc.source = "${dotfiles}/inputrc";
}
