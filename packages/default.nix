final: prev:

{
  philiptaron = {
    btop = final.callPackage ./btop.nix { };
    llm = final.callPackage ./llm.nix { };
  };
}
