{ config, pkgs, inputs, ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelModules = [ "kvm-amd" "nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm" ];
  boot.blacklistedKernelModules = [ "amdgpu" ];

  # Make the mode 3840x1600.
  boot.kernelParams = [ "video=DP-1:3840x1600@159.95" "nvidia-modeset.hdmi_deepcolor=1" ];

  # Turn off the NVIDIA settings application
  hardware.nvidia.nvidiaSettings = false;

  # Use the latest NVIDIA out-of-tree drives.
  # See https://www.nvidia.com/en-us/drivers/unix/linux-amd64-display-archive/
  hardware.nvidia.open = false;
  hardware.nvidia.package = pkgs.linuxPackages_latest.nvidiaPackages.beta;
  boot.extraModulePackages = [ pkgs.linuxPackages_latest.nvidiaPackages.beta ];
  services.xserver.videoDrivers = [ "nvidia" ];

  # It's time to fly.
  hardware.nvidia.modesetting.enable = true;

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
