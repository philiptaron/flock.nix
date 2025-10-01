{ nixpkgs-review, philiptaron }:

nixpkgs-review.override {
  inherit (philiptaron) nix;
  withNom = true;
}
