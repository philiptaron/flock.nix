{ config, pkgs, inputs, ... }:
let
  interfaces = [ "wlan0" "wlan1" ];
  iwd = pkgs.iwd.overrideAttrs (prevAttrs: {
    preFixup = prevAttrs.preFixup + ''
      service=$out/lib/systemd/system/iwd.service
      for i in ${builtins.toString interfaces}; do
        sed -i -e "s,^After=network-pre.target.*,\0 sys-subsystem-net-devices-$i.device," $service
      done
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

  # wlan0 adjustments
  systemd.network.links = {
    "79-wlan0" = {
      matchConfig.Name = "wlan0";
      matchConfig.Type = "wlan";
      linkConfig.NamePolicy = "keep kernel";
      linkConfig.MTUBytes = "2304";
    };
  };

  # wlan0 gets created by default. Let's make wlan1.
  systemd.network.netdevs = {
    "wlan1" = {
      netdevConfig.Name = "wlan1";
      netdevConfig.Kind = "wlan";
      netdevConfig.MACAddress = "20:2b:20:ba:ec:d6";
      netdevConfig.MTUBytes = "2304";
      wlanConfig.PhysicalDevice = "phy0";
      wlanConfig.Type = "station";
    };
    "bat0" = {
      netdevConfig.Name = "bat0";
      netdevConfig.Kind = "batadv";
    };
    "bat1" = {
      netdevConfig.Name = "bat1";
      netdevConfig.Kind = "batadv";
    };
  };

  # For now, make each network receive a DHCP.
  systemd.network.networks = {
    "wlan0" = {
      matchConfig.Name = "wlan0";
      matchConfig.WLANInterfaceType = "station";
      #networkConfig.BatmanAdvanced = "bat0";
      networkConfig.DHCP = "yes";
    };
    "wlan1" = {
      matchConfig.Name = "wlan1";
      matchConfig.WLANInterfaceType = "station";
      networkConfig.BatmanAdvanced = "bat1";
    };
  };

  # Enable wifi through iwd; turn on developer mode (--developer) and debug logging (--debug)
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.package = iwd;

  # We need to make sure that iwd doesn't create or delete wlan interfaces
  networking.wireless.iwd.settings.General.UseDefaultInterface = true;

  # Prioritize 5Ghz 50x over 2.4 GHz
  networking.wireless.iwd.settings.Rank.BandModifier5Ghz = "8.0";

  environment.systemPackages = with pkgs; [
    # `batctl` are the controls for the B.A.T.M.A.N. advanced mesh tool.
    batctl

    # `iw` is a new nl80211 based CLI configuration utility for wireless devices.
    # https://wireless.wiki.kernel.org/en/users/Documentation/iw
    iw

    # Brings `iwpriv`, `iwconfig`, `iwgetid`, `iwspy`, `iwevent`, `ifrename`, and `iwlist` tools.
    # These are old but still work. https://github.com/HewlettPackard/wireless-tools
    wirelesstools
  ];
}
