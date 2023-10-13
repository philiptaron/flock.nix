{ config, pkgs, inputs, ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelModules = [ "kvm-amd" ];

  # Make the mode 3840x1600
  boot.kernelParams = [ "video=efifb:mode=0" ];

  # Turn off the NVIDIA settings application
  hardware.nvidia.nvidiaSettings = false;

  # Use the latest NVIDIA out-of-tree drives.
  # See https://www.nvidia.com/en-us/drivers/unix/linux-amd64-display-archive/
  hardware.nvidia.open = false;
  hardware.nvidia.package = pkgs.linuxPackages_latest.nvidiaPackages.latest;
  boot.extraModulePackages = [ pkgs.linuxPackages_latest.nvidiaPackages.latest ];
  services.xserver.videoDrivers = [ "nvidia" ];

  # Let's keep using X for another week.
  hardware.nvidia.modesetting.enable = false;

  hardware.nvidia.prime.nvidiaBusId = "PCI:1:0:0";
  hardware.nvidia.prime.amdgpuBusId = "PCI:17:0:0";

  # Enable networking through systemd-networkd
  systemd.network.enable = true;
  networking.dhcpcd.enable = false;
  systemd.network.networks = {
    "wlan" = {
      matchConfig.Type = "wlan";
      networkConfig.DHCP = "yes";
    };
  };

  # Enable wifi through iwd
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.General.UseDefaultInterface = true;

  environment.systemPackages = with pkgs; [
    # `iw` is a new nl80211 based CLI configuration utility for wireless devices.
    # https://wireless.wiki.kernel.org/en/users/Documentation/iw
    iw

    # Brings `iwpriv`, `iwconfig`, `iwgetid`, `iwspy`, `iwevent`, `ifrename`, and `iwlist` tools.
    # These are old but still work. https://github.com/HewlettPackard/wireless-tools
    wirelesstools
  ];

  # Enable Bluetooth, and work around a double free (!) by telling the service to restart.
  hardware.bluetooth.enable = true;
  systemd.services.bluetooth = {
    startLimitIntervalSec = 500;
    startLimitBurst = 5;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 2;
  };
}
