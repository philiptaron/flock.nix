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
    llm = callPackage ./llm.nix { };
  };
}
