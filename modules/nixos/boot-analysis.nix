# Capture boot-time analysis on every boot.
#
# `systemd-analyze` only works for the *current* boot, so anything not saved
# before the next reboot is gone. Two minutes after boot this writes the
# timing views, the unit plot, the journal, and enough identifying context to
# /var/log/boot-analysis/<timestamp>-<boot-id>/ so that any two generations
# can be compared after the fact. `latest` always points at the newest one.
{ pkgs, ... }:

let
  capture = pkgs.writeShellApplication {
    name = "boot-analysis-capture";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd
    ];
    text = ''
      export SYSTEMD_PAGER=
      root=/var/log/boot-analysis
      out="$root/$(date +%Y-%m-%dT%H-%M-%S)-$(cut -c1-8 /proc/sys/kernel/random/boot_id)"
      mkdir -p "$out"
      cd "$out"

      systemd-analyze time > time.txt
      systemd-analyze blame > blame.txt
      systemd-analyze critical-chain > critical-chain.txt
      # What the user actually waits for is the display manager, not
      # graphical.target (which is gated by whatever service finishes last).
      systemd-analyze critical-chain display-manager.service \
        > critical-chain-display-manager.txt 2>&1 || true
      systemd-analyze plot > plot.svg

      systemctl show \
        -p FirmwareTimestampMonotonic \
        -p LoaderTimestampMonotonic \
        -p KernelTimestampMonotonic \
        -p InitRDTimestampMonotonic \
        -p UserspaceTimestampMonotonic \
        -p FinishTimestampMonotonic \
        > timestamps.txt

      # ACPI Firmware Performance Data Table: the only breakdown of the time
      # before the bootloader ran.
      if [ -d /sys/firmware/acpi/fpdt/boot ]; then
        for f in /sys/firmware/acpi/fpdt/boot/*; do
          printf '%s %s\n' "$(basename "$f")" "$(cat "$f")"
        done > fpdt.txt
      fi

      journalctl -b -o short-monotonic > journal.txt
      journalctl -b -k -o short-monotonic > dmesg.txt

      {
        echo "booted-system:  $(readlink /run/booted-system)"
        echo "current-system: $(readlink /run/current-system)"
        echo "cmdline:        $(cat /proc/cmdline)"
        echo "kernel:         $(uname -r)"
      } > system.txt

      ln -sfn "$out" "$root/latest"
    '';
  };
in
{
  systemd.services.boot-analysis = {
    description = "Capture boot-time analysis for this boot";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${capture}/bin/boot-analysis-capture";
      LogsDirectory = "boot-analysis";
      LogsDirectoryMode = "0755";
    };
  };

  systemd.timers.boot-analysis = {
    description = "Capture boot-time analysis shortly after boot";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      # Not Persistent: this is per-boot data, catching up would be meaningless.
    };
  };

  # Keep 180 days of captures.
  systemd.tmpfiles.rules = [ "d /var/log/boot-analysis 0755 root root 180d" ];
}
