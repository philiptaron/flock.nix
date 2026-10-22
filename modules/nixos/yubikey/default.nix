# YubiKey support: `ykman`, the PC/SC daemon, and a desktop notification when the key wants a touch.
#
# This stands in for nixpkgs' `programs.yubikey-manager` and `programs.yubikey-touch-detector`.
# Those add udev rules that only match keys with the OTP interface enabled (systemd's own
# `60-fido-id` and `70-uaccess` rules already grant access to FIDO and CCID), run the detector
# through the deprecated `LIBNOTIFY` variable, and always enable a socket nothing listens on.
#
# The FIDO side (`hidraw`) is visible to the detector because the kernel copies every input report
# to every reader, so it sees the CTAPHID "user presence needed" keepalive. The CCID side (PIV,
# OpenPGP over PC/SC) is not: `pcscd` holds the USB device exclusively. The detector also watches
# gpg-agent, but only when `~/.gnupg/private-keys-v1.d` holds on-card (shadowed) keys at startup.
#
# While a YubiKey waits for a touch on a smartcard command, it answers with CCID time extensions:
# the first about 200 ms after the command, then one every 290 ms or so. `ccid-touch-varlink.patch`
# makes libccid, pcscd's driver, report those over Varlink on /run/pcscd/ccid-touch:
#
#   varlinkctl call --more --timeout=infinity /run/pcscd/ccid-touch \
#     io.github.philiptaron.CcidTouch.Watch '{}'
#
# The patches are `git format-patch` exports of branches in the `h` clones of the upstreams.
{ lib, pkgs, ... }:

let
  ccid = pkgs.ccid.overrideAttrs (old: {
    patches = old.patches or [ ] ++ [ ./ccid-touch-varlink.patch ];
    buildInputs = old.buildInputs ++ [ pkgs.systemdLibs ];
    mesonFlags = old.mesonFlags ++ [ (lib.mesonEnable "varlink" true) ];
  });
in
{
  # `ykman` and `age-plugin-yubikey` reach PIV, OATH, and OpenPGP through PC/SC.
  services.pcscd.enable = true;

  # Replace the stock libccid instead of adding a second driver for the same readers.
  services.pcscd.plugins = lib.mkForce [ ccid ];

  # `ykman` configures YubiKeys.
  # https://developers.yubico.com/yubikey-manager/
  environment.systemPackages = [ pkgs.yubikey-manager ];

  # `yubikey-touch-detector` sends a desktop notification when the YubiKey is waiting for a touch.
  # https://github.com/maximbaz/yubikey-touch-detector
  systemd.user.services.yubikey-touch-detector = {
    description = "Notify when the YubiKey is waiting for a touch";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];

    # The gpg-agent watcher runs `gpgconf --list-dirs` and `gpgconf --launch gpg-agent`.
    path = [ pkgs.gnupg ];

    serviceConfig = {
      ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --notify --no-socket";
      Restart = "on-failure";
    };
  };
}
