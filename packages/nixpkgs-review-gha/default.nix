{ pkgs, ... }:

let
  python = pkgs.python3.withPackages (ps: [ (ps.toPythonModule pkgs.nixpkgs-review) ]);
in

pkgs.writeShellApplication {
  name = "nixpkgs-review-gha";
  runtimeInputs = [ pkgs.gh ];
  text = ''
    exec ${python}/bin/python ${./nixpkgs-review-gha.py} "$@"
  '';
}
