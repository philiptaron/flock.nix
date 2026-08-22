{ lib, pkgs, ... }:

{
  # Use Limine bootloader to set GOP resolution before Linux boots.
  # This gives simpledrm native resolution instead of firmware's 1024x768 default.
  boot.loader.limine.enable = true;
  boot.loader.limine.efiInstallAsRemovable = true; # Install to fallback path so firmware boots Limine by default
  boot.loader.limine.resolution = "3840x1600x32"; # Framebuffer for Linux/simpledrm
  boot.loader.limine.style.interface.resolution = "3840x1600"; # Bootloader menu
  boot.loader.efi.canTouchEfiVariables = true;

  # Show the generation menu briefly; the default 5s was the single largest
  # software-controlled chunk of boot time.
  boot.loader.timeout = 1;

  # Use systemd in the initrd.
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;
  boot.initrd.systemd.emergencyAccess = true;

  # Root is a plain ext4 partition on NVMe found via gpt-auto, so the initrd
  # only needs the NVMe driver plus what systemd itself requires. The NixOS
  # default list pulls in AHCI and the USB stack, which made the initrd wait
  # ~3.7s for udevd to finish enumerating slow USB devices (webcam, USB audio)
  # and probing ten empty SATA ports before it could switch root. Those now
  # enumerate after switch-root, in parallel with the rest of userspace.
  #
  # Trade-off: no USB keyboard in the initrd emergency shell. Older generations
  # in the Limine menu still carry USB-capable initrds if that's ever needed.
  boot.initrd.includeDefaultModules = false;
  boot.initrd.availableKernelModules = lib.mkForce [
    "autofs4" # systemd's automount support
    "efivarfs"
    "nvme"
  ];

  # Preload ext4 rather than letting the kernel usermode-helper modprobe it
  # mid-mount; that modprobe took 1.5s during the udev coldplug storm.
  boot.initrd.kernelModules = [ "ext4" ];

  console.enable = true;
  console.earlySetup = true;
  console.packages = [ pkgs.terminus_font ];
  console.font = "ter-132n"; # Terminus 32px normal

  # Request 175Hz refresh rate for when NVIDIA takes over from simpledrm.
  # Limine sets the GOP resolution (3840x1600), these params set the refresh rate.
  # The LG 38GL950G EDID has 60Hz as preferred, but we want 175Hz.
  # The connector may appear as DP-1, DP-2, or DP-3 depending on GPU port.
  boot.kernelParams = [
    "video=DP-1:3840x1600@175"
    "video=DP-2:3840x1600@175"
    "video=DP-3:3840x1600@175"
  ];

  # No software RAID in this system.
  boot.swraid.enable = false;

  # Use `systemd-gpt-auto-root` to detect the root filesystem partition.
  boot.initrd.supportedFilesystems = [ "ext4" ];
  boot.initrd.systemd.root = "gpt-auto";

  # No swap devices in this system (maybe a bad call.)
  swapDevices = [ ];

  # Compressed swap in RAM so systemd-oomd has a real memory-pressure signal;
  # without any swap it logs "memory pressure usage will be degraded".
  zramSwap.enable = true;

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
