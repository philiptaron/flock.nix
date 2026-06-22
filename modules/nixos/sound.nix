{
  # Enable sound with pipewire and Bluetooth
  services.pulseaudio.enable = false;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.pulse.enable = true;

  # Turn off speech-dispatcher.
  services.speechd.enable = false;

  # RealtimeKit service hands out realtime scheduling priority to user processes on demand.
  # pipewire and wireplumber services use this to acquire realtime priority.
  security.rtkit.enable = true;
}
