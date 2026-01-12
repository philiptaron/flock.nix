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
git remote add systemd https://github.com/systemd/systemd.git
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

## systemd-boot Graphics Investigation (2026-01-12)

### Summary
systemd-boot does NOT change the GOP (graphics) mode - it only handles EFI console
text modes. The graphics resolution and refresh rate are set entirely by UEFI firmware
based on the monitor's EDID preferred mode.

### Code Analysis

**GOP mode (graphics)**: Never touched by systemd-boot.
```c
// systemd/main:src/boot/console.c:192 - only READS GOP info
EFI_STATUS query_screen_resolution(uint32_t *ret_w, uint32_t *ret_h) {
    err = BS->LocateProtocol(MAKE_GUID_PTR(EFI_GRAPHICS_OUTPUT_PROTOCOL), NULL, (void **) &go);
    *ret_w = go->Mode->Info->HorizontalResolution;  // read only
    *ret_h = go->Mode->Info->VerticalResolution;    // read only
}
```

**Console mode (text)**: The 'r' key cycles through EFI text modes, not graphics modes.
```c
// systemd/main:src/boot/boot.c:844
case KEYPRESS(0, 0, 'r'):
    err = console_set_mode(CONSOLE_MODE_NEXT);  // text mode, not GOP
```

**Splash images**: Drawn via GOP->Blt() without changing mode.
```c
// systemd/main:src/boot/splash.c:304
err = GraphicsOutput->Blt(GraphicsOutput, &background, EfiBltVideoFill, ...);
```

### Implications

The boot sequence before Linux:
```
1. UEFI POST      → firmware reads EDID, sets GOP to preferred mode (60Hz)
2. systemd-boot   → uses GOP as-is, only changes console text mode
3. simpledrm      → uses GOP framebuffer directly, no mode change
```

The first actual display mode change happens when nvidia-drm loads and applies
the video= kernel parameter. There is no way to set GOP mode from systemd-boot
to avoid this initial 60Hz → 175Hz transition.

## MSI BIOS Analysis (2026-01-12)

### System Info

| Component | Value |
|-----------|-------|
| Motherboard | MSI MPG X670E CARBON WIFI (MS-7D70) |
| BIOS Vendor | American Megatrends International (AMI) |
| BIOS Version | 1.R1 (analyzed 1.R6) |
| Platform | AMD X670E (AM5), AGESA PI 1.2.0.3g |

### Analysis Method

```bash
# Extracted and analyzed using fiano
nix-shell -p fiano --run "utk E7D70AMS.1R6 extract /tmp/bios_extract"

# Searched for graphics-related modules and strings
strings E7D70AMS.1R6 | grep -iE "gop|display|graphics"
```

### Key Graphics Modules

| GUID | Module | Purpose |
|------|--------|---------|
| `665E3FF5-46CC-11D4-9A38-0090273FC14D` | GraphicsConsole, GraphicsOutputTools | Standard UEFI GOP |
| `13A3F0F6-264A-3EF0-F2E0-DEC512342F34` | AmdCpmDisplayFeatureDxe | AMD display features |
| `0DE50221-FAAA-45BA-90B9-7BCC26EC60CF` | AmdNbioGfxRPLDxe, CbsSetupDxeRPL | AMD NBIO graphics |
| `A0BC6E92-DB71-4EB9-8788-1A36E2705163` | AmdPbsSetupDxe | AMD Platform BIOS Settings |

### Relevant PCDs Found

```
PcdPeiGopEnable              - GOP enable in PEI phase
PcdPeiGopConfigMemsize       - GOP framebuffer size
PcdPeiGopVmFbOffset          - GOP framebuffer offset
PcdCfgIgpuContorl            - iGPU control
PcdCfgdGPUOnlyModeEnable     - dGPU-only mode
PcdDisplayCapDdi0-4          - Display DDI capabilities
PcdAmdDisplayPhyTuning*      - Display PHY tuning
```

### Findings

**Not found in BIOS:**
- No GOP mode/resolution selection options
- No EDID override capability
- No "preferred mode" configuration
- No refresh rate settings for early boot

**Conclusion:** The MSI BIOS (like most consumer boards) provides no way to configure
the GOP display mode. The firmware reads EDID and uses the monitor's preferred mode
(60Hz for the LG 38GL950G). The 60Hz → 175Hz transition when nvidia-drm loads is
**unavoidable** without custom UEFI modifications.

### Potential (Complex) Solutions

1. **Custom UEFI application** - Write app that calls `GOP->SetMode()` before systemd-boot
2. **Modified BIOS** - Patch firmware to change GOP behavior (risky, warranty-voiding)
3. **Monitor EDID mod** - Hardware EDID emulator to present 175Hz as preferred

None of these are practical. The current setup with `video=` kernel parameter achieves
the minimum possible mode switches (exactly one, when nvidia-drm loads).

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

## Phantom Display Investigation (2026-01-12)

### Problem
After enabling simpledrm and adding `video=` kernel parameters, GNOME Settings showed
two phantom displays named "1" and "3" that did nothing.

### Root Cause
The `e` suffix in `video=DP-1:3840x1600@175e` means "enable" - it forces the connector
to report as "connected" regardless of actual hardware state:

```
# From journalctl -b
[drm] forcing DP-1 connector on
[drm] forcing DP-2 connector on
[drm] forcing DP-3 connector on
nvidia-modeset: WARNING: GPU:0: Unable to read EDID for display device DP-0
nvidia-modeset: WARNING: GPU:0: Unable to read EDID for display device DP-4
```

DRM connector status after boot:
```
/sys/class/drm/card1-DP-1/status: connected  (EDID: 0 bytes - phantom!)
/sys/class/drm/card1-DP-2/status: connected  (EDID: 384 bytes - real monitor)
/sys/class/drm/card1-DP-3/status: connected  (EDID: 0 bytes - phantom!)
```

GNOME/mutter sees these as connected outputs without valid EDID, displaying them
generically as "1" and "3" (the connector index).

### Fix Applied
Removed `e` suffix from video= parameters. Without it, connector status is determined
by actual hardware detection (EDID presence), not forced on:

```nix
boot.kernelParams = [
  "video=DP-1:3840x1600@175"   # was @175e
  "video=DP-2:3840x1600@175"
  "video=DP-3:3840x1600@175"
];
```

### DRM Debug Parameter Reference

The `drm.debug` kernel parameter is a bitmask for enabling debug output:

| Bit | Value | Category | Description |
|-----|-------|----------|-------------|
| 0 | 0x01 | CORE | Core DRM code |
| 1 | 0x02 | DRIVER | Controller code |
| 2 | 0x04 | KMS | Modesetting code |
| 3 | 0x08 | PRIME | Prime/dmabuf code |
| 4 | 0x10 | ATOMIC | Atomic modesetting |
| 5 | 0x20 | VBL | Vblank code |
| 6 | 0x40 | STATE | Verbose atomic state |
| 7 | 0x80 | LEASE | Lease code |
| 8 | 0x100 | DP | DisplayPort code |
| 9 | 0x200 | DRMRES | Managed resources |

Source: `linux/linux-6.12.y:drivers/gpu/drm/drm_print.c`

Runtime modification: `echo 0x04 | sudo tee /sys/module/drm/parameters/debug`

## simpledrm Quality Investigation (2026-01-12)

### Problem
After fixing the phantom displays, simpledrm still looked terrible during early boot -
clearly a low resolution stretched across the 3840x1600 panel.

### Root Cause
DRM debug logging (`drm.debug=0x06`) revealed the EFI GOP framebuffer is only 1024x768:

```
simple-framebuffer simple-framebuffer.0: [drm:simpledrm_probe] display mode={"": 60 47185 1024 1024 1024 1024 768 768 768 768 0x40 0x0}
simple-framebuffer simple-framebuffer.0: [drm:simpledrm_probe] framebuffer format=XR24 little-endian (0x34325258), size=1024x768, stride=4096 byte
simple-framebuffer simple-framebuffer.0: [drm:simpledrm_probe] using I/O memory framebuffer at [mem 0xf000000000-0xf0002fffff flags 0x200]
```

The memory region size confirms this: `0xf0002fffff - 0xf000000000 = 3MB = 1024×768×4 bytes`.

simpledrm inherits whatever GOP mode the UEFI firmware provides. The NVIDIA GPU's GOP ROM
(embedded in the MSI BIOS) is only configured to provide a basic 1024x768 framebuffer,
not the monitor's native resolution.

### Why systemd-boot consoleMode doesn't help
The `boot.loader.systemd-boot.consoleMode = "max"` setting affects EFI *text* console mode
(the character grid size), not the GOP graphics framebuffer resolution. These are separate
EFI protocols:
- `EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL` - text mode, affected by consoleMode
- `EFI_GRAPHICS_OUTPUT_PROTOCOL` (GOP) - graphics framebuffer, what simpledrm uses

### Potential Solutions

1. **Alternative bootloader (Limine, rEFInd)**
   Some bootloaders can set a specific GOP mode before chainloading or booting the kernel.
   Limine in particular supports setting the framebuffer resolution via its config file.

2. **Custom GOP ROM / VBIOS modification**
   Modify the NVIDIA GOP ROM to default to a higher resolution. Complex and risky.

3. **UEFI Shell script at boot**
   Use an EFI application to call `SetMode()` on the GOP protocol before the kernel loads.

4. **Accept the limitation**
   simpledrm is only visible for ~8 seconds during boot before NVIDIA takes over.
   The visual quality during this brief period may not justify the complexity of fixing it.

### Current Status
The phantom display issue is resolved. The simpledrm quality issue is understood but not
yet fixed - it requires bootloader changes to set an appropriate GOP mode before Linux boots.
