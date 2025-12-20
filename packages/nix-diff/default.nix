{ pkgs, ... }:

pkgs.nix-diff.overrideAttrs (prevAttrs: {
  patches = (prevAttrs.patches or [ ]) ++ [
    # Make the highlighting look a lot better.
    (pkgs.fetchpatch {
      url = "https://github.com/Gabriella439/nix-diff/commit/2f66e3dc0cd96cab76601c30eb02b02269d35e16.patch";
      hash = "sha256-UKrrng0VYAmQYw8YutByG4P3Nzz6oS97Dp27KVjyQzE=";
    })
  ];
})
