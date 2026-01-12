{ config, pkgs, ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelModules = [ "kvm-amd" ];
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Use the latest NVIDIA open drivers.
  # See https://www.nvidia.com/en-us/drivers/unix/linux-amd64-display-archive/
  # and https://github.com//NVIDIA/open-gpu-kernel-modules/
  hardware.nvidia.open = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.latest.override {
    disable32Bit = true;
  };

  # The zone of "Are we Wayland yet?" with the answer "mostly yes!".
  hardware.nvidia.modesetting.enable = true;

  # Enable power management so DPMS wake works correctly.
  # This sets NVreg_PreserveVideoMemoryAllocations=1 and enables the
  # nvidia-suspend/resume/hibernate systemd services.
  hardware.nvidia.powerManagement.enable = true;

  # Turn off the NVIDIA settings GUI. It's not for Wayland yet.
  hardware.nvidia.nvidiaSettings = false;

  # Turn on the NVIDIA NixOS module which keys on this value.
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable Bluetooth, and work around a misconfiguration in the ConfigurationDirectoryMode.
  hardware.bluetooth.enable = true;
  systemd.services.bluetooth.serviceConfig.ConfigurationDirectoryMode = "0755";
  hardware.logitech.wireless.enable = true;
}
