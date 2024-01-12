{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  specialArgs,
}:

{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Adds in `virtualisation.libvirtd.qemu.package` to the environment (a.k.a. `qemu`)
  # A generic and open source machine emulator and virtualizer
  # https://www.qemu.org/
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  virtualisation.libvirtd.qemu.ovmf.packages = with pkgs; [
    pkgsCross.aarch64-multiplatform.OVMF.fd # AAVMF
    OVMF.fd
  ];
}
