{
  # Enable sound with pipewire and Bluetooth
  services.pulseaudio.enable = false;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.pulse.enable = true;

  # Keep the S/PDIF sink always running so the Polk soundbar never loses clock lock.
  # Without this, PipeWire suspends the node when idle, the S/PDIF transmitter stops
  # sending valid frames, and the soundbar fails to re-acquire sync.
  environment.etc."wireplumber/wireplumber.conf.d/51-spdif-no-suspend.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          {
            node.name = "alsa_output.usb-Generic_USB_Audio-00.HiFi__SPDIF__sink"
          }
        ]
        actions = {
          update-props = {
            session.suspend-timeout-seconds = 0
          }
        }
      }
    ]
  '';

  # Turn off speech-dispatcher.
  services.speechd.enable = false;

  # RealtimeKit service hands out realtime scheduling priority to user processes on demand.
  # pipewire and wireplumber services use this to acquire realtime priority.
  security.rtkit.enable = true;
}
