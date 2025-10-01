{ nix-doc, philiptaron }:

nix-doc.override {
  inherit (philiptaron) nix;
}
