{
  # Python 3.12.15 refuses a server_hostname on server-side wrap_bio(), which
  # anyio 4.14.2's TLSStream.wrap() passes, so its TLS tests fail and take
  # apostrophe (and the whole system) down with them. This is my upstream fix,
  # https://github.com/agronholm/anyio/pull/1374, minus its changelog hunk.
  #
  # Nixpkgs carries the same fix with anyio 4.15.1 in
  # https://github.com/NixOS/nixpkgs/pull/569174; once that reaches the lock,
  # this no longer applies and the whole directory can go.
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyFinal: pyPrev: {
          anyio = pyPrev.anyio.overridePythonAttrs (old: {
            patches =
              (old.patches or [ ])
              ++ prev.lib.optional (old.version == "4.14.2") (
                final.fetchpatch {
                  url = "https://github.com/agronholm/anyio/commit/9a7a1d2a68ec7b8216e14ab03b778af365d6fe67.patch";
                  excludes = [ "docs/versionhistory.rst" ];
                  hash = "sha256-e7ZjHkUUSZQhD4JOVie+DdynytdbQMcpeqUTFn/yJno=";
                }
              );
          });
        })
      ];
    })
  ];
}
