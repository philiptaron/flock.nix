{ config, pkgs, inputs, ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelModules = [ "kvm-amd" ];

  # Make the mode 3840x1600
  boot.kernelParams = [ "video=efifb:mode=0" ];

  # Turn off amdgpu (conflicts with NVIDIA)
  boot.kernelPatches = with inputs.nixpkgs.lib; [{
    name = "disable-amdgpu";
    patch = null;
    extraStructuredConfig = {
      DRM_AMDGPU = kernel.no;
      DRM_AMDGPU_CIK = mkForce (kernel.option kernel.no);
      DRM_AMDGPU_SI = mkForce (kernel.option kernel.no);
      DRM_AMDGPU_USERPTR = mkForce (kernel.option kernel.no);
      DRM_AMD_DC_FP = mkForce (kernel.option kernel.no);
      DRM_AMD_DC_SI = mkForce (kernel.option kernel.no);
      HSA_AMD = mkForce (kernel.option kernel.no);
    };
  }];

  # Turn off the nvidia settings application
  hardware.nvidia.nvidiaSettings = false;
  hardware.nvidia.package = pkgs.linuxPackages_latest.nvidiaPackages.latest;
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

  # Enable bluetooth, and work around a double free (!) by telling the service to restart.
  hardware.bluetooth.enable = true;
  systemd.services.bluetooth = {
    startLimitIntervalSec = 500;
    startLimitBurst = 5;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 2;
  };
}
