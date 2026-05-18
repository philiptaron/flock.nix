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
  # fancontrol's ValidateDevices treats the hwmonN labels as literal sysfs
  # indices under /sys/class/hwmon, so the indices below must match probe
  # order: nct6687 = hwmon9, k10temp = hwmon4. If kernel updates shuffle
  # those, fancontrol.service will fail with "Device path of hwmonN has
  # changed" — update the indices to match `cat /sys/class/hwmon/*/name`.
  hardware.fancontrol = {
    enable = true;
    config = ''
      INTERVAL=10
      DEVPATH=hwmon4=devices/pci0000:00/0000:00:18.3 hwmon9=devices/platform/nct6687.2592
      DEVNAME=hwmon4=k10temp hwmon9=nct6687
      FCTEMPS=hwmon9/pwm3=hwmon4/temp1_input
      FCFANS=hwmon9/pwm3=hwmon9/fan3_input
      MINTEMP=hwmon9/pwm3=45
      MAXTEMP=hwmon9/pwm3=75
      MINSTART=hwmon9/pwm3=100
      MINSTOP=hwmon9/pwm3=70
      MINPWM=hwmon9/pwm3=70
      MAXPWM=hwmon9/pwm3=200
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
