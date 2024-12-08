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

  # Turn off the NVIDIA settings GUI. It's not for Wayland yet.
  hardware.nvidia.nvidiaSettings = false;

  # Use the latest NVIDIA out-of-tree drives.
  # See https://www.nvidia.com/en-us/drivers/unix/linux-amd64-display-archive/
  hardware.nvidia.open = false;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta.override {
    disable32Bit = true;
  };
  #boot.extraModulePackages = [ config.hardware.nvidia.package ];

  # The zone of "Are we Wayland yet?" with the answer "mostly yes!".
  hardware.nvidia.modesetting.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable Bluetooth, and work around a misconfiguration in the ConfigurationDirectoryMode.
  hardware.bluetooth.enable = true;
  systemd.services.bluetooth.serviceConfig.ConfigurationDirectoryMode = "0755";

  # OpenGL, Wayland, and DRM debugging tools.
  environment.systemPackages = with pkgs; [
    # Small utility to dump info about DRM devices.
    # https://gitlab.freedesktop.org/emersion/drm_info
    drm_info

    # Test utilities for OpenGL
    # https://dri.freedesktop.org/wiki/glxinfo/
    glxinfo

    # Tool for reading and parsing EDID data from monitors
    # http://www.polypux.org/projects/read-edid/
    read-edid

    # EDID decoder and conformance tester
    # https://git.linuxtv.org/edid-decode.git
    edid-decode

    # Provides the `vkcube`, `vkcubepp`, `vkcube-wayland`, and `vulkaninfo` tools.
    # https://github.com/KhronosGroup/Vulkan-Tools
    vulkan-tools
  ];
}
