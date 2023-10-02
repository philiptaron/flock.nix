{ config, pkgs, inputs, ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelModules = [ "kvm-amd" ];

  # Make the mode 3840x1600
  boot.kernelParams = [ "video=efifb:mode=0" ];

  # Turn off the NVIDIA settings application
  hardware.nvidia.nvidiaSettings = false;

  # Use the latest open NVIDIA packages.
  # See https://github.com/NVIDIA/open-gpu-kernel-modules
  hardware.nvidia.open = true;
  hardware.nvidia.package = pkgs.linuxPackages_latest.nvidiaPackages.latest;
  boot.extraModulePackages = [ pkgs.linuxPackages_latest.nvidiaPackages.latest ];
  boot.initrd.kernelModules = [ "nvidia" ];
  services.xserver.videoDrivers = [ "nvidia" ];

  # Let's keep using X for a week.
  hardware.nvidia.modesetting.enable = false;

  hardware.nvidia.prime.nvidiaBusId = "PCI:01:00.0";
  hardware.nvidia.prime.amdgpuBusId = "PCI:17:00.0";

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

  # Enable Bluetooth, and work around a double free (!) by telling the service to restart.
  hardware.bluetooth.enable = true;
  systemd.services.bluetooth = {
    startLimitIntervalSec = 500;
    startLimitBurst = 5;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 2;
  };
}
