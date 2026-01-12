# Claude Code wrapped with GUI sudo askpass support
{ pkgs, ... }:

let
  # Askpass helper: confirm with zenity, then retrieve password from GNOME Keyring
  sudo-askpass = pkgs.writeShellScriptBin "sudo-askpass" ''
    # Show confirmation dialog
    if ${pkgs.zenity}/bin/zenity --question --title "sudo" --text "$1"; then
      # User confirmed, retrieve password from keyring
      ${pkgs.libsecret}/bin/secret-tool lookup service sudo username "$USER"
    else
      exit 1
    fi
  '';

  # A sudo wrapper that automatically adds -A for askpass support
  sudo-wrapper = pkgs.writeShellScriptBin "sudo" ''
    # Check if -A is already in the arguments
    for arg in "$@"; do
      if [ "$arg" = "-A" ]; then
        exec ${pkgs.sudo}/bin/sudo "$@"
      fi
    done
    # Add -A if not present
    exec ${pkgs.sudo}/bin/sudo -A "$@"
  '';

  # Environment with askpass and sudo wrapper and whatever else we find that Claude needs.
  claude-env = pkgs.buildEnv {
    name = "claude-env";
    paths = [ sudo-askpass sudo-wrapper ];
  };
in
pkgs.claude-code.overrideAttrs (prevAttrs: {
  nativeBuildInputs = (prevAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];

  postInstall = (prevAttrs.postInstall or "") + ''
    wrapProgram $out/bin/claude \
      --prefix PATH : ${claude-env}/bin \
      --set SUDO_ASKPASS ${sudo-askpass}/bin/sudo-askpass
  '';
})
