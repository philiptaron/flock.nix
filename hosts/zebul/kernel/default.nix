{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_7_0;
}
