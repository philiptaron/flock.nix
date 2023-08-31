# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  nix = {
    package = pkgs.nixFlakes;
    registry.nixpkgs.flake = inputs.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "1";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.network.enable = true;

  # Use the most recent kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Make the mode 3840x1600
  boot.kernelParams = [ "video=efifb:mode=0" "module_blacklist=amdgpu" ];

  # Turn off amdgpu (conflicts with NVIDIA)
  boot.kernelPatches = with inputs.nixpkgs.lib; [{
    name = "disable-amdgpu";
    patch = null;
    extraStructuredConfig = {
      DRM_AMDGPU = kernel.no;
      DRM_AMDGPU_CIK = mkForce (kernel.option kernel.no);
      DRM_AMDGPU_SI = mkForce (kernel.option kernel.no);
      DRM_AMDGPU_USERPTR = mkForce (kernel.option kernel.no);
      DRM_AMD_DC_FP = mkForce (kernel.option kernel.no);
      DRM_AMD_DC_SI = mkForce (kernel.option kernel.no);
      HSA_AMD = mkForce (kernel.option kernel.no);
    };
  }];

  console.font = "drdos8x14";
  console.earlySetup = true;

  # Use Vim as the editor of choice.
  programs.vim.defaultEditor = true;

  # Set up networking stuff.
  networking.hostName = "zebul";

  # Enable the tailscale daemon.
  services.tailscale.enable = true;

  # Turn off the firewall altogether.
  networking.firewall.enable = false;

  # Enable networking through systemd-networkd
  systemd.network.enable = true;
  networking.dhcpcd.enable = false;
  systemd.network.networks = {
    "wlan0" = {
      matchConfig.Name = "wlan0";
      networkConfig.DHCP = "yes";
    };
  };

  # Enable wifi through iwd
  networking.wireless.iwd.enable = true;

  # Have an SSH agent
  programs.ssh.startAgent = true;

  # Try out podman
  virtualisation.podman.enable = true;

  # Enable Ubuntu container
  systemd.nspawn = {
    "ubuntu-jammy" = {
      execConfig.Capability = "all";
      execConfig.ResolvConf = "copy-stub";
      execConfig.Timezone = "copy";
      networkConfig.Private = false;
    };
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable the GNOME Desktop Environment (minimal!)
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.sessionPackages = [ pkgs.gnome.gnome-session.sessions ];

  # Turn on dconf setting. Super minimal.
  programs.dconf.enable = true;

  # Enable a TPM. Commented out due to https://hydra.nixos.org/build/233171651/nixlog/1/tail
  #security.tpm2.enable = true;
  #security.tpm2.pkcs11.enable = true;
  #security.tpm2.tctiEnvironment.enable = true;

  # Enable bluetooth, and work around a double free (!) by telling the service to restart.
  hardware.bluetooth.enable = true;
  systemd.services.bluetooth = {
    startLimitIntervalSec = 500;
    startLimitBurst = 5;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 2;
  };

  # Enable sound with pipewire and Bluetooth
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = false;
    pulse.enable = true;
  };

  # Define a user account.
  users.users.philip = {
    isNormalUser = true;
    description = "Philip Taron";
    extraGroups = [ "wheel" "tss" ];

    # These are unfree packages so they don't get installed with nix profile install
    packages = with pkgs; [
      anydesk
      freerdp
      slack
      webex
      zoom-us
    ];
  };

  environment.systemPackages = with pkgs; [
    pkgs.curl
    pkgs.wget
    inputs.agenix.packages."${pkgs.system}".default
  ];
}
