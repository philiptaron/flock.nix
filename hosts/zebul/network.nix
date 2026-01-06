{ pkgs, ... }:

{
  # `wireshark` is a network packet tracing application
  # https://www.wireshark.org/
  programs.wireshark.enable = true;

  # Use Tailscale.
  services.tailscale.enable = true;

  # Enable networking through systemd-networkd; don't use the built-in NixOS modules.
  networking.useNetworkd = true;
  systemd.network.enable = true;

  # Turn on verbose logging for systemd-networkd.
  systemd.services.systemd-networkd.serviceConfig.Environment = "SYSTEMD_LOG_LEVEL=debug";

  # Adjust wlan0 to have the highest MTU that this device offers.
  systemd.network.links = {
    "79-wlan0" = {
      matchConfig.OriginalName = "wlan0";
      matchConfig.Type = "wlan";
      linkConfig.NamePolicy = "keep kernel";
      linkConfig.MTUBytes = "2304";
    };
  };

  # Use DHCP to configure Ethernet devices.
  systemd.network.networks."ether-uses-dhcp" = {
    matchConfig.Type = "ether";
    matchConfig.Name = "e*";
    networkConfig.DHCP = "yes";
    dhcpV4Config.UseMTU = true;
  };

  # Don't use DHCP in general, though, especially not with scripted networking.
  networking.useDHCP = false;

  networking.firewall.enable = true;
  networking.nftables.enable = true;

  # Allow reverse path filtering to be more permissive for libvirt
  networking.firewall.checkReversePath = false;

  # Trust the libvirt bridge so VMs can get DHCP and reach the host
  networking.firewall.trustedInterfaces = [ "virbr0" ];
}
