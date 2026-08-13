{ pkgs, perSystem, ... }:

let
  dotfiles = perSystem.self.dotfiles;
  philiptaron = {
    inherit (perSystem.self)
      alacritty
      btop
      htop
      hyperfine
      llm
      claude-code
      ;
  };
in
{
  # Use Vim as the editor of choice.
  programs.vim.enable = true;
  programs.vim.defaultEditor = true;

  # `firefox` is a web browser.
  # http://www.mozilla.com/en-US/firefox/
  programs.firefox.enable = true;
  programs.firefox.package = perSystem.self.firefox;

  # Turn on polkit (ew)
  security.polkit.enable = true;

  # Turn on PCSC-Lite daemon.
  services.pcscd.enable = true;

  # Turn on sudo explicitly. In time, let's explore having other privilege escalators.
  security.sudo.enable = true;

  # Some NixOS packages provide debug symbols. However, these are not included in the system closure
  # by default to save disk space. Enabling this option causes the debug symbols to appear in
  # `/run/current-system/sw/lib/debug/.build-id`, where tools such as `gdb` can find them.
  environment.enableDebugInfo = true;

  # I use `callPackage` as a way to avoid having with statements or prefix everything with `pkgs.`
  environment.systemPackages = pkgs.callPackage ./system-packages.nix { inherit philiptaron; };
  users.users.philip.packages = pkgs.callPackage ./philip-packages.nix {
    inherit philiptaron;
  };

  systemd.user.tmpfiles.users.philip.rules = [
    "L+ %h/.config/alacritty/alacritty.toml - - - - ${dotfiles}/alacritty.toml"
    "L+ %h/.config/gdb/gdbinit - - - - ${dotfiles}/gdbinit"
  ];
}
