{ nix-index, philiptaron }:

nix-index.override {
  inherit (philiptaron) nix;
}
