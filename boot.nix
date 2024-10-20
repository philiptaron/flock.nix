{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  specialArgs,
}:

let
  udevConf = pkgs.writeText "udev.conf" "udev_log=debug";
in
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;

  # Use systemd in the initrd.
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;
  boot.initrd.systemd.emergencyAccess = true;
  boot.initrd.systemd.managerEnvironment.SYSTEMD_LOG_LEVEL = "debug";

  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "sd_mod"
    "usb_storage"
    "usbhid"
    "xhci_pci"
  ];

  boot.initrd.extraFiles."etc/udev/udev.conf".source = udevConf;
  environment.etc."udev/udev.conf".source = udevConf;

  console.enable = true;

  # Enable a TPM.
  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true;
  security.tpm2.tctiEnvironment.enable = true;
  environment.systemPackages = with pkgs; [ tpm2-tools ];

  # No software RAID in this system.
  boot.swraid.enable = false;

  # Use `systemd-gpt-auto-root` to detect the root filesystem partition.
  boot.initrd.supportedFilesystems = [ "ext4" ];
  boot.initrd.systemd.root = "gpt-auto";

  # Mount the boot partition specifically. I'd like to move this to a mount unit.
  fileSystems."/boot".device = "/dev/disk/by-uuid/0D2C-FF36";
  fileSystems."/boot".fsType = "vfat";

  # No swap devices in this system (maybe a bad call.)
  swapDevices = [ ];

  # We're in Tacoma, WA, USA.
  location.latitude = 47.2656321;
  location.longitude = -122.4575112;

  # We're in the Pacific time zone.
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
      "libvirtd"
      "tss"
      "wheel"
      "wireshark"
    ];
  };
}
