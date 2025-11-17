let
  inherit (builtins) unsafeDiscardStringContext getFlake;
  root = unsafeDiscardStringContext "${./.}";
  flake = getFlake root;
in
flake.outputs.nixosConfigurations.zebul
