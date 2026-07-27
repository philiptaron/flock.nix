{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_7_1;

  # Suppress the codec-less AMD HD-audio controller (0000:17:00.6) that this
  # MSI X670E board exposes. It has no codec wired to it, so every boot logs
  # "snd_hda_intel 0000:17:00.6: no codecs found!" and registers an empty
  # card. Audio actually runs through the MSI USB audio device (see
  # ../sound.nix). This mirrors the kernel's existing denylist entry for the
  # sibling MSI X870E Tomahawk; it is in upstreamable form for alsa-devel.
  boot.kernelPatches = [
    {
      name = "hda/intel: denylist codec-less HDA controller on MSI X670E Carbon";
      patch = ./0001-hda-intel-denylist-x670e-carbon.patch;
    }
  ];
}
