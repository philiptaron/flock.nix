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
  #scan-service = (interface: {
  #  name = "iwd-${interface}-scan";
  #  value = {
  #    wantedBy = [ "iwd.service" ];
  #    after = [ "iwd.service" ];
  #    startLimitIntervalSec = 500;
  #    startLimitBurst = 5;
  #    serviceConfig = {
  #      ExecStart = "${iwd}/bin/iwctl station ${interface} scan";
  #      Restart = "on-failure";
  #      RestartSec = 1;
  #    };
  #  };
  #});
  #connect-service = (name: {
  #  name = "iwd-${name}-connect";
  #  value = {
  #    wantedBy = [ "iwd-${name}-scan.service" ];
  #    after = [ "iwd-${name}-scan.service" ];
  #    startLimitIntervalSec = 500;
  #    startLimitBurst = 5;
  #    serviceConfig = {
  #      ExecStart = "${iwd}/bin/iwctl station ${name} connect Taron";
  #      Restart = "on-failure";
  #      RestartSec = 1;
  #    };
  #  };
  #});
  #services = let
  #  functions = [scan-service connect-service];
  #  fold = items: builtins.foldl' (x: y: x // y) {} items;
  #  result = with builtins; fold (listToAttrs (concatMap (f: map f interfaces) functions));
  #in result;
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
      wlanConfig.PhysicalDevice = 0;
      wlanConfig.Type = "station";
    };
  };

  # For now, make each network receive a DHCP.
  systemd.network.networks = {
    "wlan" = {
      matchConfig.Type = "wlan";
      matchConfig.WLANInterfaceType = "station";
      networkConfig.DHCP = "yes";
      dhcpV4Config.Anonymize = "yes";
    };
  };

  # Enable wifi through iwd; turn on developer mode (--developer) and debug logging (--debug)
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.package = iwd;

  # We need to make sure that iwd doesn't create or delete wlan interfaces
  networking.wireless.iwd.settings.General.UseDefaultInterface = true;

  # Prioritize 5Ghz 50x over 2.4 GHz
  networking.wireless.iwd.settings.Rank.BandModifier5Ghz = "50.0";

  #systemd.services."iwd-scan@" = {
  #  after = [ "iwd.service" ];
  #  startLimitIntervalSec = 500;
  #  startLimitBurst = 5;
  #  serviceConfig = {
  #    ExecStart = "${iwd}/bin/iwctl station %i scan";
  #    Restart = "on-failure";
  #    RestartSec = 1;
  #  };
  #};
  #systemd.services."iwd-connect@" = {
  #  after = [ "iwd-scan@%i.service" ];
  #  startLimitIntervalSec = 500;
  #  startLimitBurst = 5;
  #  serviceConfig = {
  #    ExecStart = "${iwd}/bin/iwctl station %i scan";
  #    Restart = "on-failure";
  #    RestartSec = 1;
  #  };
  #};

  environment.systemPackages = with pkgs; [
    # `iw` is a new nl80211 based CLI configuration utility for wireless devices.
    # https://wireless.wiki.kernel.org/en/users/Documentation/iw
    iw

    # Brings `iwpriv`, `iwconfig`, `iwgetid`, `iwspy`, `iwevent`, `ifrename`, and `iwlist` tools.
    # These are old but still work. https://github.com/HewlettPackard/wireless-tools
    wirelesstools
  ];
}
