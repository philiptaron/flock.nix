{ config, pkgs, inputs, ... }:

{
  # Use the most recent kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

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
}
