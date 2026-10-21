{
  # electron-source.electron_44 44.9.1 fails at gn gen with a duplicate
  # `v8_snapshot_toolchain` build argument, on Hydra too, which takes
  # signal-desktop (and the whole system) down with it. Build Signal against
  # Electron's prebuilt binary instead; it has the `headers` and `dist` that
  # Signal's build needs.
  #
  # https://github.com/NixOS/nixpkgs/issues/576736 tracks the failure, and
  # https://github.com/NixOS/nixpkgs/pull/576806 fixes it; once that reaches
  # the lock, this no longer applies and the file can go.
  nixpkgs.overlays = [
    (final: prev: {
      signal-desktop =
        if prev.electron_44.version == "44.9.1" then
          prev.signal-desktop.override { electron_44 = final.electron_44-bin; }
        else
          prev.signal-desktop;
    })
  ];
}
