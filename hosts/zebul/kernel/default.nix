{ lib, pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_12;

  boot.kernelPatches = [
    {
      name = "turn off simpledrm in an attempt to remove an extra monitor with NVIDIA";
      patch = null;
      structuredExtraConfig = {
        DRM_SIMPLEDRM = lib.mkForce lib.kernel.no;
      };
    }
  ];
}
