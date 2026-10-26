# sudo takes a YubiKey touch, every time, and nothing else.
#
# `u2f_keys` maps users to FIDO credentials, made with:
#
#   pamu2fcfg -u philip -o pam://zebul -i pam://zebul
#
# A credential is a key handle and a public key, useless without the YubiKey that made it.
# Append a line from another key to register a backup.
{ ... }:

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
  };

  # Every sudo takes its own touch.
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=0
  '';
}
