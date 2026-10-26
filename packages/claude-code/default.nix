# Claude Code wrapped with a sudo that names the command in a notification
{ pkgs, perSystem, ... }:

let
  agent-env = perSystem.self.agent-env;
in
pkgs.claude-code.overrideAttrs (prevAttrs: {
  nativeBuildInputs = (prevAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];

  postInstall = (prevAttrs.postInstall or "") + ''
    wrapProgram $out/bin/claude \
      --prefix PATH : ${agent-env}/bin
  '';
})
