{
  description = "Philip Taron's flock of Nix configuration(s)";
  nixConfig.commit-lockfile-summary = "flake.nix: update the lockfile";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  # Nixpkgs 26.11 dropped x86_64-darwin; 26.05 gets security fixes through the end of 2026.
  # selene (an Intel Mac) builds from this instead of `nixpkgs`.
  inputs.nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
  inputs.systems.url = "github:nix-systems/default";

  inputs.blueprint.url = "github:philiptaron/blueprint";
  inputs.blueprint.inputs.nixpkgs.follows = "nixpkgs";
  inputs.blueprint.inputs.systems.follows = "systems";

  # My version of the h tool
  inputs.h.url = "github:philiptaron/h";
  inputs.h.inputs.nixpkgs.follows = "nixpkgs";
  inputs.h.inputs.systems.follows = "systems";

  inputs.h-darwin.url = "github:philiptaron/h";
  inputs.h-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
  inputs.h-darwin.inputs.systems.follows = "systems";

  # Vim plugins (flake = false means they're just source trees)
  inputs.vim-autoformat.url = "github:Chiel92/vim-autoformat";
  inputs.vim-autoformat.flake = false;

  inputs.vim-nix.url = "github:LnL7/vim-nix";
  inputs.vim-nix.flake = false;

  inputs.editorconfig-vim.url = "github:editorconfig/editorconfig-vim";
  inputs.editorconfig-vim.flake = false;

  inputs.promptline-vim.url = "github:edkolev/promptline.vim";
  inputs.promptline-vim.flake = false;

  inputs.vim-ripgrep.url = "github:jremmen/vim-ripgrep";
  inputs.vim-ripgrep.flake = false;

  inputs.vim-better-whitespace.url = "github:ntpeters/vim-better-whitespace";
  inputs.vim-better-whitespace.flake = false;

  inputs.vim-abolish.url = "github:tpope/vim-abolish";
  inputs.vim-abolish.flake = false;

  inputs.vim-dispatch.url = "github:tpope/vim-dispatch";
  inputs.vim-dispatch.flake = false;

  inputs.vim-endwise.url = "github:tpope/vim-endwise";
  inputs.vim-endwise.flake = false;

  inputs.vim-repeat.url = "github:tpope/vim-repeat";
  inputs.vim-repeat.flake = false;

  inputs.vim-surround.url = "github:tpope/vim-surround";
  inputs.vim-surround.flake = false;

  inputs.vim-unimpaired.url = "github:tpope/vim-unimpaired";
  inputs.vim-unimpaired.flake = false;

  inputs.vim-airline.url = "github:vim-airline/vim-airline";
  inputs.vim-airline.flake = false;

  inputs.vim-airline-themes.url = "github:vim-airline/vim-airline-themes";
  inputs.vim-airline-themes.flake = false;

  # Load the blueprint, once for x86_64-darwin with `nixpkgs-darwin` and once for everything else.
  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;

      blueprint =
        args:
        inputs.blueprint (
          args
          // {
            nixpkgs.config.allowUnfree = true;
          }
        );

      main = blueprint {
        inherit inputs;
        systems = lib.remove "x86_64-darwin" (import inputs.systems);
      };

      darwin = blueprint {
        inputs = inputs // {
          nixpkgs = inputs.nixpkgs-darwin;
          h = inputs.h-darwin;
        };
        systems = [ "x86_64-darwin" ];
      };

      perSystemOutputs = [
        "checks"
        "devShells"
        "formatter"
        "legacyPackages"
        "packages"
      ];
    in
    main // lib.genAttrs perSystemOutputs (name: main.${name} // darwin.${name});
}
