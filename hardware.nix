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
  }] ++ [{
    name = "remove-scary-amd-error-message";
    patch = ./amd_pinconf_set.patch;
  }];

  # Turn off the nvidia settings application
  hardware.nvidia.nvidiaSettings = false;

  # Enable networking through systemd-networkd
  systemd.network.enable = true;
  networking.dhcpcd.enable = false;
  systemd.network.networks = {
    "wlan0" = {
      matchConfig.Name = "wlan0";
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

  # Enable sound with pipewire and Bluetooth
  services.pipewire.enable = true;
}
