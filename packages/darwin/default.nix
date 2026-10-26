# This is a poor man's `nix-darwin`.
# Install with `nix profile install github:philiptaron/flock.nix#darwin`
# You might need to clear out all other installed items.
{ pkgs, perSystem, ... }:

pkgs.symlinkJoin {
  name = "darwin";

  # I use `callPackage` as a way to avoid having with statements or prefix everything with `pkgs.`
  paths = pkgs.callPackage ./packages.nix {
    philiptaron = {
      # The identities I run `h` under here, as hosts/zebul/h.nix does for zebul: a wrapped
      # binary each, with its code root, object store and git options baked in.
      h = perSystem.self.h.override {
        identities = {
          h = {
            root = "~/Code";
            store = "~/.cache/git/philiptaron";
            gitOpts = ''-c user.name="Philip Taron" -c user.email="philip.taron@gmail.com" -c user.signingkey="~/.ssh/personal_id_ed25519.pub" -c credential.username="philiptaron"'';
          };
          hq = {
            root = "~/Qumulo";
            store = "~/.cache/git/PhilipTaronQ";
            gitOpts = ''-c user.name="Philip Taron" -c user.email="philip@qumulo.com" -c user.signingkey="~/.ssh/qumulo_id_ed25519.pub" -c credential.username="PhilipTaronQ"'';
          };
        };
      };
      llm = perSystem.self.llm;
      nix = perSystem.self.nix;
      nix-diff = perSystem.self.nix-diff;
      nix-doc = perSystem.self.nix-doc;
      nix-index = perSystem.self.nix-index;
      nix-update = perSystem.self.nix-update;
      nixpkgs-review = perSystem.self.nixpkgs-review;
    };
  };
}
