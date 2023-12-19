{ config, lib, modulesPath, options, pkgs, specialArgs }:

{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.systemPackages = with pkgs; [
    # `qemu` is a virtualization toolkit that can run and emulate virtual machines
    # https://www.qemu.org
    qemu_full
  ];

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
}
