{ config, pkgs, ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  # Fan control for MSI X670E NCT6687D chip
  boot.extraModulePackages = [ config.boot.kernelPackages.nct6687d ];
  boot.kernelModules = [
    "kvm-amd"
    "nct6687" # Module name differs from package name (nct6687d)
    "i2c-dev"
  ];

  # Radiator fans live on the Phanteks Nexus+ 2 hub, plugged into the
  # SYS_FAN #1 header (pwm3 on the nct6687). Curve targets k10temp Tctl.
  # hwmonN indices follow probe order, which isn't stable across boots (the
  # spd5118 DIMM sensors race the nct6687), so the config uses absolute paths
  # through /run/fancontrol/<name> symlinks that preStart rebuilds by driver
  # name. With absolute paths fancontrol skips its DEVPATH/DEVNAME checks.
  hardware.fancontrol = {
    enable = true;
    config = ''
      INTERVAL=10
      FCTEMPS=/run/fancontrol/nct6687/pwm3=/run/fancontrol/k10temp/temp1_input
      FCFANS=/run/fancontrol/nct6687/pwm3=/run/fancontrol/nct6687/fan3_input
      MINTEMP=/run/fancontrol/nct6687/pwm3=45
      MAXTEMP=/run/fancontrol/nct6687/pwm3=75
      MINSTART=/run/fancontrol/nct6687/pwm3=100
      MINSTOP=/run/fancontrol/nct6687/pwm3=70
      MINPWM=/run/fancontrol/nct6687/pwm3=70
      MAXPWM=/run/fancontrol/nct6687/pwm3=200
    '';
  };
  systemd.services.fancontrol = {
    serviceConfig.RuntimeDirectory = "fancontrol";
    preStart = ''
      for hwmon in /sys/class/hwmon/hwmon*; do
        name=$(cat "$hwmon/name")
        case "$name" in
          k10temp | nct6687) ln -sfn "$hwmon" "/run/fancontrol/$name" ;;
        esac
      done
      test -e /run/fancontrol/k10temp && test -e /run/fancontrol/nct6687
    '';
  };

  # Sensor and I2C tools
  environment.systemPackages = [
    pkgs.lm_sensors
    pkgs.i2c-tools
  ];
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Use the latest NVIDIA open drivers.
  # See https://www.nvidia.com/en-us/drivers/unix/linux-amd64-display-archive/
  # and https://github.com//NVIDIA/open-gpu-kernel-modules/
  hardware.nvidia.open = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.latest.override {
    disable32Bit = true;
  };

  # The zone of "Are we Wayland yet?" with the answer "mostly yes!".
  hardware.nvidia.modesetting.enable = true;

  # Enable power management so DPMS wake works correctly.
  # This sets NVreg_PreserveVideoMemoryAllocations=1 and enables the
  # nvidia-suspend/resume/hibernate systemd services.
  hardware.nvidia.powerManagement.enable = true;

  # Turn off the NVIDIA settings GUI. It's not for Wayland yet.
  hardware.nvidia.nvidiaSettings = false;

  # Turn on the NVIDIA NixOS module which keys on this value.
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable Bluetooth, and work around a misconfiguration in the ConfigurationDirectoryMode.
  hardware.bluetooth.enable = true;
  systemd.services.bluetooth.serviceConfig.ConfigurationDirectoryMode = "0755";
  hardware.logitech.wireless.enable = true;
}
