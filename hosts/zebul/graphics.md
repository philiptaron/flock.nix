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
git remote add gdm https://gitlab.gnome.org/GNOME/gdm.git
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

### Fixes Applied

1. **Kernel cmdline (fbdev console)** - Added `video=DP-X:3840x1600@175e` kernel
   parameters in boot.nix for DP-1, DP-2, and DP-3. When NVIDIA driver loads and
   sets up DRM fbdev console, it uses cmdline mode instead of EDID preferred.
   See `linux/linux-6.12.y:drivers/gpu/drm/drm_client_modeset.c:163` -
   `drm_connector_pick_cmdline_mode()` runs before `drm_connector_has_preferred_mode()`.

2. **GDM login screen** - Added system-wide `/etc/xdg/monitors.xml` via NixOS
   `environment.etc."xdg/monitors.xml"`. Mutter reads system config dirs first
   (see `mutter/main:src/backends/meta-monitor-config-store.c:2832`).

3. **User session** - Added DP-1, DP-2, DP-3 configurations to `~/.config/monitors.xml`
   with 174.971 Hz refresh rate. GNOME applies this when user logs in.

### Architecture

```
Boot sequence with single mode switch:

1. UEFI/firmware → sets initial framebuffer (whatever mode GOP uses)
2. simpledrm    → uses existing framebuffer, no mode change
3. nvidia-drm   → loads, removes simpledrm, picks cmdline mode (175Hz)
                  via video=DP-X:3840x1600@175e kernel parameters
4. GDM/mutter   → reads /etc/xdg/monitors.xml, already at 175Hz
5. User session → reads ~/.config/monitors.xml, still 175Hz

Only one mode switch: step 3 when NVIDIA takes over from simpledrm.
```

The kernel `video=` parameter sets `DRM_MODE_TYPE_USERDEF` on the mode, which
takes precedence over `DRM_MODE_TYPE_PREFERRED` from EDID.

Mutter's monitors.xml is loaded from two locations:
```
g_get_system_config_dirs()  →  /etc/xdg/monitors.xml      (system config)
g_get_user_config_dir()     →  ~/.config/monitors.xml     (user config, takes precedence)
```

### Seamless Mutter Handoff

When mutter starts (GDM or user session), it always queues a "mode set" via
`meta_renderer_native_queue_modes_reset()`. However, the kernel's atomic helper
compares old vs new state:

```c
// linux/linux-6.12.y:drivers/gpu/drm/drm_atomic_helper.c:667
if (!drm_mode_equal(&old_crtc_state->mode, &new_crtc_state->mode)) {
    new_crtc_state->mode_changed = true;
}
```

If the modes are identical, `mode_changed = false`. NVIDIA's driver respects this:

```c
// nvidia/main:kernel-open/nvidia-drm/nvidia-drm-crtc.c:2415
if (crtc_state->mode_changed) {
    req_config->flags.modeChanged = NV_TRUE;
}
```

With matching modes, only framebuffer/plane updates occur (during VBLANK, no blanking).
The same logic applies to `active_changed` and `connectors_changed` - all must be
false for truly seamless transition.

Key code paths:
- Kernel mode comparison: `linux/linux-6.12.y:drivers/gpu/drm/drm_modes.c` `drm_mode_equal()`
- NVIDIA atomic check: `nvidia/main:kernel-open/nvidia-drm/nvidia-drm-crtc.c:2415`
- Mutter mode set queue: `mutter/main:src/backends/native/meta-renderer-native.c:1313`

### Why Not EDID Override?

The 175Hz mode requires 1218.5 MHz pixel clock, but standard EDID DTD format
only supports 16-bit pixel clock field (max ~655.35 MHz). That's why LG put
the high refresh rates in DisplayID Extension Block 2 instead of the base
EDID block. We can't simply swap DTDs.

### EDID Reference

```bash
# Extract current EDID (384 bytes for this monitor)
cat /sys/class/drm/card0-DP-2/edid > /tmp/original.edid

# Decode EDID structure
nix-shell -p edid-decode --run "edid-decode /tmp/original.edid"
```

NVIDIA driver does support DRM EDID override (`drm.edid_firmware`), but it's not
needed since the `video=` kernel parameter achieves the same goal more simply.
See `nvidia/main:kernel-open/nvidia-drm/nvidia-drm-connector.c:104` for override handling.
