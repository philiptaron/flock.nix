{ config, pkgs, inputs, ... }:
let
  iwd = pkgs.iwd.overrideAttrs (prevAttrs: {
    preFixup = prevAttrs.preFixup + ''
      service=$out/lib/systemd/system/iwd.service

      # Make sure the iwd service starts after the wlan0 interface
      sed -i -e "s,^After=network-pre.target.*,\0 sys-subsystem-net-devices-wlan0.device," $service

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
  # Let's hack it with a one-shot service. Yes, that's the BSS of my wifi.
  systemd.services.iwd-scan = {
    wantedBy = [ "iwd.service" ];
    after = [ "iwd.service" ];
    startLimitIntervalSec = 500;
    startLimitBurst = 15;
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "iwd-scan-and-connect.sh" ''
        set -ex
        ${iwd}/bin/iwctl adapter phy0 set-property Powered on
        ${iwd}/bin/iwctl adapter phy0 show
        ${iwd}/bin/iwctl device wlan0 set-property Powered on
        ${iwd}/bin/iwctl device wlan0 show
        ${iwd}/bin/iwctl station wlan0 scan
        while ${iwd}/bin/iwctl station wlan0 show | grep Scanning | grep -q no; do
          sleep 0.1
        done
        ${iwd}/bin/iwctl station wlan0 show
        ${iwd}/bin/iwctl debug wlan0 connect e8:9f:80:67:6c:56
        ${iwd}/bin/iwctl station wlan0 show
      '';
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  environment.systemPackages = with pkgs; [
    # `batctl` are the controls for the B.A.T.M.A.N. advanced mesh tool.
    batctl

    # `iw` is a new nl80211 based CLI configuration utility for wireless devices.
    # It doesn't work super well since it doesn't know how to make use of WPA to authenticate.
    # https://wireless.wiki.kernel.org/en/users/Documentation/iw
    iw
  ];
}
