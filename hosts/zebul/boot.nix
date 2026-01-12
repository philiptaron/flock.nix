{ config, pkgs, ... }:

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

  # Force 175Hz refresh rate from the start to avoid mode switches.
  # The LG 38GL950G EDID has 60Hz as preferred, but we want 175Hz.
  # This applies to DRM fbdev console; monitors.xml handles GDM and user session.
  # The connector may appear as DP-1, DP-2, or DP-3 depending on GPU port.
  boot.kernelParams = [
    "video=DP-1:3840x1600@175"
    "video=DP-2:3840x1600@175"
    "video=DP-3:3840x1600@175"
    "drm.debug=0x06" # KMS + DRIVER debug logging
  ];

  # No software RAID in this system.
  boot.swraid.enable = false;

  # Use `systemd-gpt-auto-root` to detect the root filesystem partition.
  boot.initrd.supportedFilesystems = [ "ext4" ];
  boot.initrd.systemd.root = "gpt-auto";

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
      "podman"
      "tss"
      "wheel"
      "wireshark"
    ];
  };
}
