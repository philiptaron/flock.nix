{ config, pkgs, inputs, ... }:
let
  interfaces = [ "wlan0" ];
  iwd = pkgs.iwd.overrideAttrs (prevAttrs: {
    preFixup = prevAttrs.preFixup + ''
      service=$out/lib/systemd/system/iwd.service
      for i in ${builtins.toString interfaces}; do
        sed -i -e "s,^After=network-pre.target.*,\0 sys-subsystem-net-devices-$i.device," $service
      done
      # Turn on developer mode (--developer) and debug logging (--debug)
      sed -i -e 's,^ExecStart=.*/iwd$,\0 --developer --debug,' $service
    '';
  });
in {
  # Enable networking through systemd-networkd; don't use the built-in NixOS modules.
  networking.useDHCP = false;
  networking.dhcpcd.enable = false;
  networking.useNetworkd = false;
  systemd.network.enable = true;

  # Turn on verbose logging for systemd-networkd.
  systemd.services.systemd-networkd.serviceConfig.Environment = "SYSTEMD_LOG_LEVEL=debug";

  # Adjust wlan0 to have the highest MTU that this device offers.
  systemd.network.links = {
    "79-wlan0" = {
      matchConfig.Name = "wlan0";
      matchConfig.Type = "wlan";
      linkConfig.NamePolicy = "keep kernel";
      linkConfig.MTUBytes = "2304";
    };
  };

  # Use DHCP to configure wlan0.
  systemd.network.networks = {
    "wlan0" = {
      matchConfig.Name = "wlan0";
      matchConfig.WLANInterfaceType = "station";
      networkConfig.DHCP = "yes";
    };
  };

  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.package = iwd;

  # We need to make sure that iwd doesn't create or delete wlan interfaces
  networking.wireless.iwd.settings.General.UseDefaultInterface = true;

  # Prioritize 5Ghz 50x over 2.4 GHz
  networking.wireless.iwd.settings.Rank.BandModifier5Ghz = "8.0";

  # For some reason, iwd doesn't like to just scan and connect to known networks at startup.
  # Let's hack it with a postStart script.
  systemd.services.iwd.postStart = ''
    set -x

    until ${iwd}/bin/iwctl station wlan0 scan; do
      echo Retrying scan on exit code $?
      ${pkgs.coreutils}/bin/sleep 1
    done

    until ${iwd}/bin/iwctl station wlan0 connect Taron; do
      echo Retrying connect to Taron SSID on exit code $?
      ${pkgs.coreutils}/bin/sleep 1
    done
  '';

  environment.systemPackages = with pkgs; [
    # `batctl` are the controls for the B.A.T.M.A.N. advanced mesh tool.
    batctl

    # `iw` is a new nl80211 based CLI configuration utility for wireless devices.
    # It doesn't work super well since it doesn't keep trying to scan and connect to known networks.
    # https://wireless.wiki.kernel.org/en/users/Documentation/iw
    iw
  ];
}
