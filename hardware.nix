{ config, pkgs, inputs, ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelModules = [ "kvm-amd" ];
  boot.blacklistedKernelModules = [ ];

  # Make the mode 3840x1600, because that's what efifb mode 0 is like.
  boot.kernelParams = [ "video=efifb:mode=0" "video=efifb:list" ];

  # Turn off the NVIDIA settings GUI.
  hardware.nvidia.nvidiaSettings = false;

  # Use the latest NVIDIA out-of-tree drives.
  # See https://www.nvidia.com/en-us/drivers/unix/linux-amd64-display-archive/
  hardware.nvidia.open = false;
  hardware.nvidia.package = pkgs.linuxPackages_latest.nvidiaPackages.latest;
  boot.extraModulePackages = [ pkgs.linuxPackages_latest.nvidiaPackages.latest ];

  # Turn off kernel mode setting and keep on using X.
  hardware.nvidia.modesetting.enable = false;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.displayManager.gdm.wayland = false;

  # These settings don't do anything right now. They're correct with respect to zebul, though.
  hardware.nvidia.prime.nvidiaBusId = "PCI:1:0:0";
  hardware.nvidia.prime.amdgpuBusId = "PCI:17:0:0";

  # Enable Bluetooth, and work around a double free (!) by telling the service to restart.
  hardware.bluetooth.enable = true;
  systemd.services.bluetooth = {
    startLimitIntervalSec = 500;
    startLimitBurst = 5;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 1;
  };
}
