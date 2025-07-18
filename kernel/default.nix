{ lib, pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_12;

  boot.kernelPatches = [
    {
      name = "crypto_larval_add logs when adding an algorithm";
      patch = ./crypto_larval_add-logging.patch;
    }
    {
      name = "user-mode helper subsystem logs when it runs something";
      patch = ./umh-logging.patch;
    }
    {
      name = "turn off simpledrm in an attempt to remove an extra monitor with NVIDIA";
      patch = null;
      extraStructuredConfig = {
        DRM_SIMPLEDRM = lib.mkForce lib.kernel.no;
      };
    }
  ];
}
