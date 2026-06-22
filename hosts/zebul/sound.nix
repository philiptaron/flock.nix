{
  # Zebul audio topology
  # =====================
  #
  # This machine (MSI X670E board, EVGA GA102/RTX 3090 Ti) exposes *three*
  # independent audio subsystems. Only one of them is actually used, so the
  # boot log is noisy with failures from the other two. None of that is a
  # problem; the notes below exist so we don't keep re-investigating it.
  #
  # 1. MSI onboard USB audio chip  -- THE ONE WE USE
  #      USB id 0db0:d6e7 "Micro Star International USB Audio", wired internally
  #      to the AMD 600-series chipset USB controller (0000:14:00.0, port 3-9).
  #      It shows up as ALSA card "Generic USB Audio" / PipeWire node
  #      "alsa_output.usb-Generic_USB_Audio-00.HiFi__SPDIF__sink".
  #      Its optical S/PDIF output feeds the Polk soundbar. This path works on
  #      every boot and is the default sink. The no-suspend rule below keeps it
  #      from dropping clock lock (see comment on the rule).
  #
  # 2. Realtek ALC1220 analog codec  -- DEAD, UNUSED
  #      PCI 0000:17:00.6 "AMD Ryzen HD Audio Controller", DeviceName "Realtek
  #      ALC1220". The codec has NEVER enumerated on this machine -- every boot
  #      logs:
  #          snd_hda_intel 0000:17:00.6: no codecs found!
  #      and ALSA registers an empty card2 with no codec#0. This drives the
  #      analog 3.5mm jacks, which we don't use. The message is harmless; do
  #      not chase it unless the analog jacks are ever actually needed (then
  #      it's a BIOS "HD Audio Controller" / kernel-quirk investigation).
  #
  # 3. Nvidia GA102 HDMI/DP audio  -- WORKS, but effectively unusable here
  #      PCI 0000:01:00.1, ALSA card "HDA NVidia". The codec enumerates fine.
  #      The only sink the GPU sees is the LG 38GL950G monitor on DisplayPort
  #      (card1-DP-3, valid audio ELD), and that monitor has no speakers -- only
  #      a headphone passthrough jack. No HDMI device (e.g. the soundbar over
  #      HDMI/ARC) ever completes an audio handshake: all HDMI pins read
  #      monitor_present=0. So "Nvidia audio doesn't work" is expected -- there's
  #      simply nowhere for its output to go. Stay on the optical S/PDIF path.

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
}
