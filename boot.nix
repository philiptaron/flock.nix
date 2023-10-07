{ config, pkgs, inputs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the most recent kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Made things slower to boot.
  #boot.initrd.systemd = {
  #  enable = true;
  #  network.enable = true;
  #  emergencyAccess = true;
  #  managerEnvironment = {
  #    SYSTEMD_LOG_LEVEL = "debug";
  #  };
  #};

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.swraid.enable = false;

  console.font = "drdos8x14";

  # Enable a TPM.
  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true;
  security.tpm2.tctiEnvironment.enable = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/d5a0f038-5839-44e1-ad49-5edd00d7f81e";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/0D2C-FF36";
      fsType = "vfat";
    };
  };

  swapDevices = [ ];

  # We're in Tacoma, WA, USA.
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Define my user account.
  users.users.philip = {
    isNormalUser = true;
    description = "Philip Taron";
    extraGroups = [
      "pipewire"
      "tss"
      "wheel"
    ];
  };
}
