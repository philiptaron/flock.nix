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

  # wlan0 gets created by default. Let's make wlan1.
  systemd.network.netdevs = {
    "wlan1" = {
      netdevConfig.Name = "wlan1";
      netdevConfig.Kind = "wlan";
      netdevConfig.MACAddress = "20:2b:20:ba:ec:d6";
      wlanConfig.PhysicalDevice = "phy0";
      wlanConfig.Type = "station";
    };
    "bond0" = {
      netdevConfig.Name = "bond0";
      netdevConfig.Kind = "bond";
      netdevConfig.MACAddress = "20:2b:20:ba:ec:d5";
    };
  };

  # For now, make each network receive a DHCP.
  systemd.network.networks = {
    "wlan" = {
      matchConfig.Type = "wlan";
      matchConfig.WLANInterfaceType = "station";
      networkConfig.Bond = "bond0";
    };
    "bond" = {
      matchConfig.Type = "bond";
      networkConfig.DHCP = "yes";
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
    # `iw` is a new nl80211 based CLI configuration utility for wireless devices.
    # https://wireless.wiki.kernel.org/en/users/Documentation/iw
    iw

    # Brings `iwpriv`, `iwconfig`, `iwgetid`, `iwspy`, `iwevent`, `ifrename`, and `iwlist` tools.
    # These are old but still work. https://github.com/HewlettPackard/wireless-tools
    wirelesstools
  ];
}
