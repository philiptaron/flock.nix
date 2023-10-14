{ config, pkgs, inputs, ... }:

{
  # Enable networking through systemd-networkd
  systemd.network.enable = true;
  networking.dhcpcd.enable = false;
  systemd.network.networks = {
    "wlan" = {
      matchConfig.Type = "wlan";
      matchConfig.WLANInterfaceType = "station";
      networkConfig.DHCP = "yes";
      dhcpV4Config.Anonymize = "yes";
    };
  };

  # Enable wifi through iwd
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings.General.UseDefaultInterface = true;

  environment.systemPackages = with pkgs; [
    # `iw` is a new nl80211 based CLI configuration utility for wireless devices.
    # https://wireless.wiki.kernel.org/en/users/Documentation/iw
    iw

    # Brings `iwpriv`, `iwconfig`, `iwgetid`, `iwspy`, `iwevent`, `ifrename`, and `iwlist` tools.
    # These are old but still work. https://github.com/HewlettPackard/wireless-tools
    wirelesstools
  ];
}
