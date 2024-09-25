{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  specialArgs,
}:

{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelModules = [ "kvm-amd" ];
  boot.blacklistedKernelModules = [ ];

  # Turn off the NVIDIA settings GUI.
  hardware.nvidia.nvidiaSettings = false;

  # Use the latest NVIDIA out-of-tree drives.
  # See https://www.nvidia.com/en-us/drivers/unix/linux-amd64-display-archive/
  hardware.nvidia.open = false;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.latest.override {
    disable32Bit = true;
  };
  boot.extraModulePackages = [ config.hardware.nvidia.package ];

  # The zone of "Are we Wayland yet?" with the answer "mostly yes!".
  hardware.nvidia.modesetting.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.displayManager.gdm.wayland = true;

  # These settings don't do anything right now. They're correct with respect to zebul, though.
  hardware.nvidia.prime.nvidiaBusId = "PCI:1:0:0";
  hardware.nvidia.prime.amdgpuBusId = "PCI:17:0:0";

  # Enable Bluetooth.
  hardware.bluetooth.enable = true;
  environment.systemPackages = with pkgs; [ gnome-bluetooth ];
}
