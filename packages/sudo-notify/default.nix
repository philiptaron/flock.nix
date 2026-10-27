# `sudo-notify` names a sudo command in a desktop notification while sudo waits for a YubiKey
# touch, and closes it once sudo stops waiting. pam_exec runs it; see hosts/zebul/sudo.nix.
{ pkgs, ... }:

let
  inherit (pkgs) lib;
in
pkgs.buildGoModule {
  pname = "sudo-notify";
  version = "0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./go.mod
      ./go.sum
      (lib.fileset.fileFilter (file: file.hasExt "go") ./.)
    ];
  };

  vendorHash = "sha256-y+3dL8WEiN4PDHLX9/iNijS20wUheiJ+mZrM7af69G0=";

  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "Name a sudo command in a desktop notification while sudo waits for a touch";
    mainProgram = "sudo-notify";
    platforms = lib.platforms.linux;
  };
}
