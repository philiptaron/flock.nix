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
  boot.initrd.kernelModules = [ "nvidia" "amdgpu" ];
  services.xserver.videoDrivers = [ "nividia" ];

  hardware.nvidia.modesetting.enable = true;
  #hardware.nvidia.prime.sync.enable = true;
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

  # Enable Bluetooth, and work around a double free (!) by telling the service to restart.
  hardware.bluetooth.enable = true;
  systemd.services.bluetooth = {
    startLimitIntervalSec = 500;
    startLimitBurst = 5;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 2;
  };
}
