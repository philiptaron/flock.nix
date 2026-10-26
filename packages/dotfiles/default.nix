# Dotfiles collection - processed config files for various programs.
{
  pkgs,
  inputs,
  perSystem,
  ...
}:

let
  inherit (pkgs) lib;
  identities = import ../h/identities.nix;

  # Process bashrc with variable substitutions: `h` itself, and for each identity its root,
  # store and git options, quoted for the shell.
  bashrc = pkgs.replaceVars ./bash/bashrc (
    {
      h = perSystem.h.default;
    }
    // lib.concatMapAttrs (name: identity: {
      "${name}Root" = lib.escapeShellArg identity.root;
      "${name}Store" = lib.escapeShellArg identity.store;
      "${name}GitOpts" = lib.escapeShellArg identity.gitOpts;
    }) identities
  );

  # Vim plugins from flake inputs.
  vimPlugins = {
    vim-autoformat = inputs.vim-autoformat;
    vim-nix = inputs.vim-nix;
    editorconfig-vim = inputs.editorconfig-vim;
    promptline-vim = inputs.promptline-vim;
    vim-ripgrep = inputs.vim-ripgrep;
    vim-better-whitespace = inputs.vim-better-whitespace;
    vim-abolish = inputs.vim-abolish;
    vim-dispatch = inputs.vim-dispatch;
    vim-endwise = inputs.vim-endwise;
    vim-repeat = inputs.vim-repeat;
    vim-surround = inputs.vim-surround;
    vim-unimpaired = inputs.vim-unimpaired;
    vim-airline = inputs.vim-airline;
    vim-airline-themes = inputs.vim-airline-themes;
  };

  # Generate shell commands to copy each plugin.
  copyPlugins = builtins.concatStringsSep "\n" (
    pkgs.lib.mapAttrsToList (name: src: "cp -r ${src} $out/vim/pack/plugins/start/${name}") vimPlugins
  );
in
pkgs.runCommand "dotfiles" { } ''
  mkdir -p $out $out/vim/colors $out/vim/pack/plugins/start

  # Processed files
  cp ${bashrc} $out/bashrc

  # Raw files
  cp ${./alacritty/alacritty.toml} $out/alacritty.toml
  cp ${./curl/curlrc} $out/curlrc
  cp ${./gdb/gdbinit} $out/gdbinit
  mkdir -p $out/ghostty
  cp ${./ghostty/config} $out/ghostty/config
  ${
    if pkgs.stdenv.hostPlatform.isDarwin then
      "cp ${./ghostty/macos} $out/ghostty/macos"
    else
      "cp ${./ghostty/linux} $out/ghostty/linux"
  }
  cp ${./readline/inputrc} $out/inputrc
  cp ${./ssh/personal_id_ed25519.pub} $out/ssh-public-key
  cp ${./tmux/tmux.conf} $out/tmux.conf
  cp ${./vim/vimrc} $out/vim/vimrc
  cp ${./vim/colors/selenized_bw.vim} $out/vim/colors/selenized_bw.vim
  cp ${./wget/wgetrc} $out/wgetrc
  cp ${./Library/LaunchAgents/add-ssh-keys.plist} $out/add-ssh-keys.plist

  # Vim plugins
  ${copyPlugins}
''
