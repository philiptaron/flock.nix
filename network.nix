{ config, lib, modulesPath, options, pkgs, specialArgs }:

let

  wpa_supplicant = pkgs.wpa_supplicant_ro_ssids.overrideAttrs (prevAttrs: {
    extraConfig = ''
      undefine CONFIG_AP
      CONFIG_BGSCAN_LEARN=y
      CONFIG_BGSCAN_SIMPLE=y
      CONFIG_DEBUG_SYSLOG=y
      CONFIG_ELOOP=eloop
      CONFIG_EXT_PASSWORD_FILE=y
      CONFIG_HS20=y
      CONFIG_HT_OVERRIDES=y
      CONFIG_IEEE80211AC=y
      CONFIG_IEEE80211AX=y
      CONFIG_IEEE80211N=y
      CONFIG_IEEE80211R=y
      CONFIG_IEEE80211W=y
      CONFIG_INTERNETWORKING=y
      CONFIG_L2_PACKET=linux
      CONFIG_LIBNL32=y
      CONFIG_OWE=y
      CONFIG_P2P=y
      CONFIG_SAE_PK=y
      CONFIG_TDLS=y
      CONFIG_TLS=openssl
      CONFIG_TLSV11=y
      CONFIG_VHT_OVERRIDES=y
      CONFIG_WNM=y
      undefine CONFIG_WPA_CLI_EDIT
      undefine CONFIG_CTRL_IFACE_DBUS
      undefine CONFIG_CTRL_IFACE_DBUS_INTRO
      undefine CONFIG_CTRL_IFACE_DBUS_NEW
      undefine CONFIG_DRIVER_MACSEC_LINUX
      undefine CONFIG_DRIVER_NONE
      undefine CONFIG_DRIVER_WEXT
      undefine CONFIG_DRIVER_WIRED
      undefine CONFIG_EAP_EKE
      undefine CONFIG_EAP_FAST
      undefine CONFIG_EAP_GPSK
      undefine CONFIG_EAP_GPSK_SHA256
      undefine CONFIG_EAP_IKEV2
      undefine CONFIG_EAP_PAX
      undefine CONFIG_EAP_PWD
      undefine CONFIG_EAP_SAKE
      undefine CONFIG_READLINE
      undefine CONFIG_WPS
      undefine CONFIG_WPS_ER
      undefine CONFIG_WPS_NFS
    '';
    buildInputs = with pkgs; [ openssl libnl ];
  });
  iwd = pkgs.iwd.overrideAttrs (prevAttrs: {
    preFixup = prevAttrs.preFixup + ''
      service=$out/lib/systemd/system/iwd.service

      # Make sure the iwd service starts after the wlan0 interface
      sed -i -e "s,^After=network-pre.target.*,\0 sys-subsystem-net-devices-wlan0.device," $service

      # Turn on developer mode (--developer) and debug logging (--debug)
      sed -i -e 's,^ExecStart=.*/iwd$,\0 --developer --debug,' $service
    '';
  });
  iwctl = "${iwd}/bin/iwctl";
  my-bss = "e8:9f:80:67:6c:56";
  iwd-scan-and-connect = interface: pkgs.writeShellScript "iwd-scan-and-connect.sh" ''
    set -e

    # This is sadly needed to avoid 2.4Ghz connectivity.
    echo -n 1 > /sys/module/cfg80211/parameters/cfg80211_disable_40mhz_24ghz

    ${iwctl} adapter phy0 set-property Powered on
    ${iwctl} adapter phy0 show
    ${iwctl} device ${interface} set-property Powered on
    ${iwctl} device ${interface} show

    # Scan, and wait for the scan to complete
    ${iwctl} station ${interface} scan
    while ${iwctl} station ${interface} show | grep Scanning | grep -q yes; do
      echo Scanning...
      sleep 0.2
    done

    # It's likely a bug (in the kernel?) that this returns invalid argument and failed so much.
    for i in {1..6}; do
      if ${iwctl} debug ${interface} connect ${my-bss}; then
        if ${iwctl} station ${interface} show | grep ConnectedBss | grep -q "${my-bss}"; then
          ${iwctl} station ${interface} show
          exit 0
        else
          echo Claimed to connect, but actually was not connected to the correct BSS.
          ${iwctl} station ${interface} show
        fi
      fi
      echo Try $i failed
      sleep 0.2
    done

    # Before exiting and retrying the whole thing, show what the current state is.
    ${iwctl} station ${interface} show
    ${iwctl} debug ${interface} get-networks
    exit 1
  '';
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
      matchConfig.OriginalName = "wlan0";
      matchConfig.Type = "wlan";
      linkConfig.NamePolicy = "keep kernel";
      linkConfig.MTUBytes = "2304";
    };
  };

  # Use DHCP to configure wlan station devices.
  systemd.network.networks = {
    "wlan-station-uses-dhcp" = {
      matchConfig.Type = "wlan";
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
      ExecStart = iwd-scan-and-connect "wlan0";
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

    wpa_supplicant
  ];
}
