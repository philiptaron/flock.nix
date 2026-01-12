# Zebul Graphics Notes

Investigation notes for NVIDIA RTX 3090 Ti + LG 38GL950G ultrawide on Wayland/GNOME.

## Git Remotes Added

```bash
git remote add gnome-shell https://gitlab.gnome.org/GNOME/gnome-shell.git
git remote add gnome-settings-daemon https://gitlab.gnome.org/GNOME/gnome-settings-daemon.git
git remote add gnome-session https://gitlab.gnome.org/GNOME/gnome-session.git
git remote add mutter https://gitlab.gnome.org/GNOME/mutter.git
git remote add nvidia https://github.com/NVIDIA/open-gpu-kernel-modules.git
git remote add linux https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
```

## DPMS Investigation (2026-01-12)

### Problem
Monitor blanks (draws black) but doesn't actually sleep on idle. Backlight stays on.

### Root Cause
Two independent issues:

1. **gnome-settings-daemon was not installed** - Without it, nothing called
   `org.gnome.Mutter.DisplayConfig.PowerSaveMode` to send DPMS off signal.

2. **NVIDIA powerManagement not enabled** - When DPMS off was manually triggered,
   monitor slept but failed to wake (required power cycle).

### Architecture

Two independent listeners to mutter's IdleMonitor:

```
                          ┌─────────────────────────────────────┐
                          │           MUTTER                    │
                          │  org.gnome.Mutter.IdleMonitor       │
                          └──────────────┬──────────────────────┘
                                         │
                    ┌────────────────────┴────────────────────┐
                    │                                         │
                    ▼                                         ▼
     ┌──────────────────────────────┐        ┌──────────────────────────────┐
     │      GNOME-SESSION           │        │   GNOME-SETTINGS-DAEMON      │
     │  gsm-presence.c:199          │        │   gsd-power-manager.c:1948   │
     │  → StatusChanged(IDLE)       │        │   → idle_triggered_idle_cb() │
     └──────────────┬───────────────┘        └──────────────┬───────────────┘
                    │                                       │
                    ▼                                       ▼
     ┌──────────────────────────────┐        ┌──────────────────────────────┐
     │       GNOME-SHELL            │        │  backlight_disable()         │
     │  screenShield.js:249         │        │  gsd-power-manager.c:1306    │
     │  _onStatusChanged(IDLE)      │        │  → PowerSaveMode = 3 (OFF)   │
     │  → lightbox.lightOn()        │        │                              │
     └──────────────────────────────┘        └──────────────────────────────┘
                    │                                       │
                    ▼                                       ▼
            VISUAL BLACK                            MONITOR SLEEPS
     lightbox.js → .lightbox CSS                 KMS DPMS property
     { background-color: black; }
```

### Fixes Applied

1. Added `gnome-settings-daemon` to `systemd.packages` and `environment.systemPackages`
2. Added `hardware.nvidia.powerManagement.enable = true` (sets `NVreg_PreserveVideoMemoryAllocations=1`)

### NVIDIA DPMS Model

From `kernel-open/common/inc/nvkms-kapi.h`:
```c
/*
 * This distinction is for DPMS:
 *  DPMS On  : enabled=true, active=true
 *  DPMS Off : enabled=true, active=false
 */
NvBool bActive;
```

Wake happens implicitly via atomic modesetting - setting CRTC_ID re-enables output.

## simpledrm Investigation (2026-01-12)

### Problem
simpledrm was disabled ~6 months ago due to duplicate monitor bug with NVIDIA.

### Finding
NVIDIA driver 590.48.01 now properly removes simpledrm via:
```c
// nvidia-drm-drv.c:2035
drm_aperture_remove_conflicting_pci_framebuffers(pdev, &nv_drm_driver);
```

### Fix Applied
Re-enabled simpledrm (removed kernel patch). Should restore early boot graphics.

## Refresh Rate Investigation (2026-01-12)

### Problem
Monitor defaults to 60Hz, takes time to switch to 175Hz maximum.

### Root Cause
EDID declares 60Hz as preferred mode (first DTD in base block):
```
DTD 1:  3840x1600   59.993925 Hz  ← Preferred (first detailed timing)
```

Higher refresh rates only in DisplayID Extension Block 2:
```
DTD:  3840x1600  119.982290 Hz
DTD:  3840x1600  143.997958 Hz
DTD:  3840x1600  159.951563 Hz
DTD:  3840x1600  174.971281 Hz  ← What we want
```

### Partial Fix
Added DP-2 to `~/.config/monitors.xml` (was missing - only had DP-1 and DP-3).

### TODO: Better Solutions

1. **Custom EDID override** - Create modified EDID with 175Hz as first DTD,
   load via `drm.edid_firmware` kernel parameter

2. **Kernel patch** - Modify DRM mode selection to prefer highest refresh rate
   instead of EDID "preferred" mode. Relevant code locations:
   - `linux/linux-6.12.y:drivers/gpu/drm/drm_edid.c` - EDID parsing
   - `linux/linux-6.12.y:drivers/gpu/drm/drm_modes.c` - Mode preference
   - `mutter/main:src/backends/meta-monitor.c` - Mutter mode selection

3. **NVIDIA-specific** - Check if nvidia-drm has mode preference override:
   - `nvidia/main:kernel-open/nvidia-drm/nvidia-drm-connector.c`

### EDID Override Approach

```bash
# Extract current EDID
cat /sys/class/drm/card0-DP-2/edid > /tmp/original.edid

# Modify EDID (swap DTD order, recalculate checksum)
# Load via kernel parameter:
drm.edid_firmware=DP-2:edid/custom-38gl950g.bin

# Or via NixOS:
hardware.firmware = [ customEdidPackage ];
boot.kernelParams = [ "drm.edid_firmware=DP-2:edid/custom-38gl950g.bin" ];
```

Note: NVIDIA may ignore `drm.edid_firmware` - see NVIDIA forums thread.
Alternative: Use NVIDIA's own EDID override mechanism if available.
