{ config, lib, modulesPath, options, pkgs, specialArgs }:

{
  environment.systemPackages = with pkgs; [
    # `qemu` is a virtualization toolkit that can run and emulate virtual machines
    # https://www.qemu.org
    qemu_full
  ];

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
}
