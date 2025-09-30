final: prev:

{
  philiptaron = {
    btop = final.callPackage ./btop.nix { };
    htop = final.callPackage ./htop.nix { };
    llm = final.callPackage ./llm.nix { };
  };
}
