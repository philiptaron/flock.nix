# Shared environment for AI coding agents with sudo askpass support
{ pkgs, ... }:

let
  # Askpass helper: confirm with zenity, then retrieve password from GNOME Keyring
  # The prompt ($1) contains the command via sudo -p
  sudo-askpass = pkgs.writeShellScriptBin "sudo-askpass" ''
    # Show confirmation dialog - $1 is the prompt set by sudo -p
    if ${pkgs.zenity}/bin/zenity --question --title "sudo" --text "$1"; then
      # User confirmed, retrieve password from keyring
      ${pkgs.libsecret}/bin/secret-tool lookup service sudo username "$USER"
    else
      exit 1
    fi
  '';

  # A sudo wrapper that automatically adds -A for askpass support
  # Uses /run/wrappers/bin/sudo which has setuid on NixOS
  sudo-wrapper = pkgs.writeShellScriptBin "sudo" ''
    # Check if -A is already in the arguments
    for arg in "$@"; do
      if [ "$arg" = "-A" ]; then
        exec /run/wrappers/bin/sudo -p "Run: $*" "$@"
      fi
    done
    # Add -A if not present
    exec /run/wrappers/bin/sudo -p "Run: $*" -A "$@"
  '';
in
pkgs.buildEnv {
  name = "agent-env";
  paths = [ sudo-askpass sudo-wrapper ];
  passthru = { inherit sudo-askpass; };
}
