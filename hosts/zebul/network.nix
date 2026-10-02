{ pkgs, ... }:

{
  # `wireshark` is a network packet tracing application
  # https://www.wireshark.org/
  programs.wireshark.enable = true;

  # Use Tailscale.
  services.tailscale.enable = true;

  # Serve as a Tailscale peer relay for tailnet devices that can't connect directly
  # (e.g. behind CGNAT abroad), so they relay through zebul instead of DERP.
  # zebul sits directly on the cable modem with a public IPv4, so no port forward is needed.
  # Which devices may use the relay is controlled by a `tailscale.com/cap/relay` grant in the tailnet policy.
  # https://tailscale.com/docs/features/peer-relay
  services.tailscale.extraSetFlags = [ "--relay-server-port=40000" ];
  networking.firewall.allowedUDPPorts = [ 40000 ];

  # Enable networking through systemd-networkd; don't use the built-in NixOS modules.
  networking.useNetworkd = true;
  systemd.network.enable = true;

  # Adjust wlan0 to have the highest MTU that this device offers.
  # Match on the driver rather than the kernel-assigned name, which udev warns
  # is "potentially unpredictable".
  systemd.network.links = {
    "79-wlan0" = {
      matchConfig.Driver = "mt7921e";
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

  # Join the house Wi-Fi (the Linksys) only to reach devices on its LAN; internet stays on the
  # wired modem link, because the Linksys corrupts traffic leaving its wired ports.
  # iwd associates; networkd does DHCP. The passphrase lives in /var/lib/iwd/Taron.psk,
  # outside the Nix store.
  networking.wireless.iwd.enable = true;
  systemd.network.networks."wlan-house-lan" = {
    matchConfig.Type = "wlan";
    networkConfig.DHCP = "ipv4";
    networkConfig.IPv6AcceptRA = false;
    dhcpV4Config = {
      UseGateway = false;
      UseDNS = false;
      UseDomains = false;
      UseHostname = false;
    };
    linkConfig.RequiredForOnline = "no";
  };

  # Don't use DHCP in general, though, especially not with scripted networking.
  networking.useDHCP = false;

  networking.firewall.enable = true;
  networking.nftables.enable = true;

  # Allow reverse path filtering to be more permissive for libvirt
  networking.firewall.checkReversePath = false;

  # Trust the libvirt bridge so VMs can get DHCP and reach the host
  networking.firewall.trustedInterfaces = [ "virbr0" ];

  # libvirt turns on IP forwarding, and zebul sits on a public IPv4 directly on the cable modem.
  # Drop forwarded traffic by default so zebul never routes between networks (e.g. from its ISP
  # segment into the house LAN); only VMs on the libvirt bridge may start forwarded connections.
  networking.firewall.filterForward = true;
  networking.firewall.extraForwardRules = ''
    iifname "virbr0" accept comment "libvirt VMs reach out through the host"
  '';
}
