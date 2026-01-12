# Gemini CLI wrapped with GUI sudo askpass support
{ pkgs, perSystem, ... }:

let
  agent-env = perSystem.self.agent-env;
in
pkgs.gemini-cli.overrideAttrs (prevAttrs: {
  nativeBuildInputs = (prevAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];

  postInstall = (prevAttrs.postInstall or "") + ''
    wrapProgram $out/bin/gemini \
      --prefix PATH : ${agent-env}/bin \
      --set SUDO_ASKPASS ${agent-env.sudo-askpass}/bin/sudo-askpass
  '';
})
