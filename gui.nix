{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  specialArgs,
}:

{
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

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

  # Enable discovery of stuff. We'll try to get a smaller hammer over time.
  environment.pathsToLink = [ "/share" ];
}
