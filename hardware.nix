{ config, pkgs, inputs, ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelModules = [ "kvm-amd" ];

  # Make the mode 3840x1600
  #boot.kernelParams = [ "video=DP-1:3840x1600@174" ];

  # Turn off amdgpu (conflicts with NVIDIA)
  #boot.kernelPatches = with inputs.nixpkgs.lib; [{
  #  name = "disable-amdgpu";
  #  patch = null;
  #  extraStructuredConfig = {
  #    DRM_AMDGPU = kernel.no;
  #    DRM_AMDGPU_CIK = mkForce (kernel.option kernel.no);
  #    DRM_AMDGPU_SI = mkForce (kernel.option kernel.no);
  #    DRM_AMDGPU_USERPTR = mkForce (kernel.option kernel.no);
  #    DRM_AMD_DC_FP = mkForce (kernel.option kernel.no);
  #    DRM_AMD_DC_SI = mkForce (kernel.option kernel.no);
  #    HSA_AMD = mkForce (kernel.option kernel.no);
  #  };
  #}];

  # Try the NVIDIA open drivers
  hardware.nvidia.open = true;

  ## Turn on the nvidia settings application
  #hardware.nvidia.nvidiaSettings = true;

  ## Use the latest NVIDIA drivers
  hardware.nvidia.package = pkgs.linuxPackages_latest.nvidiaPackages.latest;
  #boot.extraModulePackages = [ pkgs.linuxPackages_latest.nvidiaPackages.latest ];

  ## Use NVIDIA in the initrd
  #boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  #hardware.nvidia.modesetting.enable = true;

  ## The bus IDs are a string matching the pattern ([[:print:]]+[:@][0-9]{1,3}:[0-9]{1,2}:[0-9])?'
  ## If lspci shows the NVIDIA GPU at "01:00.0", set this option to "PCI:1:0:0".
  hardware.nvidia.prime.offload.enable = true;
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

  # Enable bluetooth, and work around a double free (!) by telling the service to restart.
  hardware.bluetooth.enable = true;
  systemd.services.bluetooth = {
    startLimitIntervalSec = 500;
    startLimitBurst = 5;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 2;
  };
}
