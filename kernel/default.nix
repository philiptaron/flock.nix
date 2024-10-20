{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  specialArgs,
}:

{
  boot.kernelPackages = pkgs.linuxPackages_latest;

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
      name = "fix problems with netfilter in 6.11.4";
      patch = ./fix-netfilter-6.11.4.patch;
    }
  ];
}
