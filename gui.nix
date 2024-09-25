{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  specialArgs,
}:

let
  # COSMIC is off due to issues with Zoom screen sharing.
  enableCosmic = false;

  cosmicSettings = {
    services.desktopManager.cosmic.enable = false;
    services.displayManager.cosmic-greeter.enable = true;

    # Remove a few things
    environment.cosmic.excludePackages = with pkgs; [
      fira
      cosmic-edit
      cosmic-term
    ];
  };

  # Enable GNOME for now
  enableGnome = true;
  gnomeSettings = {
    services.xserver.desktopManager.gnome.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.gnome.core-utilities.enable = false;
    services.gnome.tracker-miners.enable = false;
    services.gnome.tracker.enable = false;
  };
in

{
  # Make the fonts look better.
  fonts = {
    enableDefaultPackages = false;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
    ];

    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "Noto Sans Mono" ];
    };
  };

  environment.systemPackages = with pkgs; [
    # Small utility to dump info about DRM devices.
    # https://gitlab.freedesktop.org/emersion/drm_info
    drm_info

    # Test utilities for OpenGL
    # https://dri.freedesktop.org/wiki/glxinfo/
    glxinfo

    # Tool for reading and parsing EDID data from monitors
    # http://www.polypux.org/projects/read-edid/
    read-edid

    # EDID decoder and conformance tester
    # https://git.linuxtv.org/edid-decode.git
    edid-decode

    # Provides the `vkcube`, `vkcubepp`, `vkcube-wayland`, and `vulkaninfo` tools.
    # https://github.com/KhronosGroup/Vulkan-Tools
    vulkan-tools
  ];
}
// (lib.optionalAttrs enableCosmic cosmicSettings)
// (lib.optionalAttrs enableGnome gnomeSettings)
