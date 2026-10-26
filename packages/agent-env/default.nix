# Shared environment for AI coding agents: a sudo that says what it's about to run
{ pkgs, ... }:

let
  # sudo takes a YubiKey touch, which says nothing about the command. Name it in a notification
  # so the touch approves something specific. This is a courtesy, not a gate: anything can call
  # /run/wrappers/bin/sudo (the setuid one on NixOS) directly, so a touch request with no
  # notification deserves suspicion.
  sudo-wrapper = pkgs.writeShellScriptBin "sudo" ''
    ${pkgs.libnotify}/bin/notify-send --app-name sudo --icon dialog-password "sudo" "Run: $*" || true
    exec /run/wrappers/bin/sudo "$@"
  '';
in
pkgs.buildEnv {
  name = "agent-env";
  paths = [
    sudo-wrapper
  ];
}
