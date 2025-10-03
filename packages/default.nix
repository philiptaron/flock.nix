final:

let
  inherit (final) callPackage;
in

prev:

{
  philiptaron = {
    alacritty = callPackage ./alacritty.nix { };
    btop = callPackage ./btop.nix { };
    htop = callPackage ./htop.nix { };
    hyperfine = callPackage ./hyperfine.nix { };
    llm = callPackage ./llm.nix { };
    nix = callPackage ./nix.nix { };
    nix-diff = callPackage ./nix-diff.nix { };
    nix-doc = callPackage ./nix-doc.nix { };
    nix-eval-jobs = callPackage ./nix-eval-jobs.nix { };
    nix-index = callPackage ./nix-index.nix { };
    nix-update = callPackage ./nix-update.nix { };
    nixpkgs-review = callPackage ./nixpkgs-review.nix { };
    nurl = callPackage ./nurl.nix { };
  };
}
