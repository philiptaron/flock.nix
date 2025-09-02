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
      structuredExtraConfig = {
        DRM_SIMPLEDRM = lib.mkForce lib.kernel.no;
      };
    }
    # Fix the /proc/net/tcp seek issue
    # Impacts tailscale: https://github.com/tailscale/tailscale/issues/16966
    {
      name = "proc: fix missing pde_set_flags() for net proc files";
      patch = pkgs.fetchurl {
        name = "fix-missing-pde_set_flags-for-net-proc-files.patch";
        url = "https://patchwork.kernel.org/project/linux-fsdevel/patch/20250821105806.1453833-1-wangzijie1@honor.com/raw/";
        hash = "sha256-DbQ8FiRj65B28zP0xxg6LvW5ocEH8AHOqaRbYZOTDXg=";
      };
    }
  ];
}
