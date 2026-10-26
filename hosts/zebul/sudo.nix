# sudo takes a YubiKey touch, every time, and nothing else.
#
# `u2f_keys` maps users to FIDO credentials, made with:
#
#   pamu2fcfg -u philip -o pam://zebul -i pam://zebul
#
# A credential is a key handle and a public key, useless without the YubiKey that made it.
# Append a line from another key to register a backup.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Name the command in a desktop notification before the touch, so it approves something
  # specific. `pam_exec` forks this from sudo, so the parent's argv is the sudo command line,
  # whoever typed it.
  notify = pkgs.writeShellScript "sudo-notify" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.libnotify
        pkgs.util-linux
      ]
    }

    mapfile -d "" -t argv < "/proc/$PPID/cmdline"
    # Quote the arguments that need it, the way they'd be typed.
    command=
    for arg in "''${argv[@]}"; do
      [[ $arg =~ ^[[:alnum:]_./:=@%+,#-]+$ ]] || arg=''${arg@Q}
      command+="$arg "
    done
    command=''${command% }

    # The notification body is markup. The replacements are quoted because bash's
    # `patsub_replacement` reads a bare `&` in them as the matched text.
    command=''${command//&/"&amp;"}
    command=''${command//</"&lt;"}
    command=''${command//>/"&gt;"}

    uid=$(id -u "$PAM_USER") || exit 0
    bus=/run/user/$uid/bus
    [ -S "$bus" ] || exit 0

    # `pam_exec` runs this with sudo's real user ID, which is root or the user depending on how far
    # sudo has gotten; only root needs to drop to the user to reach their session bus.
    drop=()
    if [ "$(id -u)" -eq 0 ]; then
      drop=(setpriv --reuid="$uid" --regid="$(id -g "$PAM_USER")" --init-groups)
    fi

    DBUS_SESSION_BUS_ADDRESS=unix:path=$bus "''${drop[@]}" \
      notify-send --app-name sudo --icon dialog-password "Touch the YubiKey to run" "$command"
  '';
in
{
  # Configure `pam_u2f` without adding it to every PAM service; only sudo turns it on below.
  # https://developers.yubico.com/pam-u2f/
  security.pam.u2f.settings = {
    # Read the mapping from a root-owned file. The default, `~/.config/Yubico/u2f_keys`, can be
    # rewritten by anything running as me.
    authfile = "/etc/u2f_keys";
    origin = "pam://zebul";
    appid = "pam://zebul";

    # Say "Please touch the device." instead of waiting silently.
    cue = true;
  };

  environment.etc."u2f_keys".source = ./u2f_keys;

  # A touch is the only way through: `pam_u2f` is sufficient, and without `pam_unix` the next line
  # is `pam_deny`. The way in without the YubiKey is the Limine editor; see boot.nix.
  security.pam.services.sudo = {
    u2f.enable = true;
    unixAuth = false;

    # Before the touch, say what it's for.
    rules.auth.notify = {
      order = config.security.pam.services.sudo.rules.auth.u2f.order - 10;
      control = "optional";
      modulePath = "${pkgs.linux-pam}/lib/security/pam_exec.so";
      args = [
        "quiet"
        "${notify}"
      ];
    };
  };

  # Every sudo takes its own touch.
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=0
  '';
}
