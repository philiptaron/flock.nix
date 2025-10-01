{ nix-update, philiptaron }:

nix-update.override {
  inherit (philiptaron) nix;
}
