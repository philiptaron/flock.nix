{
  # `bash-completion` is programmable completion functions for bash.
  # https://github.com/scop/bash-completion
  bash-completion,

  # `bashInteractive` is the GNU Bourne-Again Shell, with readline support.
  # https://www.gnu.org/software/bash/
  bashInteractive,

  # `bat` is a modern `cat` written in Rust with sweet features.
  # https://github.com/sharkdp/bat
  bat,

  # `cacert` is a bundle of X.509 certificates of public Certificate Authorities.
  # https://curl.se/docs/caextract.html
  cacert,

  # `fd` is a simple, fast and user-friendly alternative to find.
  # https://github.com/sharkdp/fd
  fd,

  # `findutils` is GNU Find Utilities, the basic directory searching utilities.
  # https://www.gnu.org/software/findutils/
  findutils,

  # `gh` is the command line GitHub client.
  # https://cli.github.com/
  gh,

  # `git` is the fast, distributed version control system.
  # https://git-scm.com/
  git,

  # `gping` is ping, but with a graph.
  # https://github.com/orf/gping
  gping,

  # `h` is a faster shell history search.
  # https://github.com/zimbatm/h
  h,

  # `jq` is a lightweight and flexible command-line JSON processor.
  # https://stedolan.github.io/jq/
  jq,

  # `lima` launches Linux virtual machines on macOS.
  # https://lima-vm.io/
  lima,

  # `man` is an implementation of the standard Unix documentation system.
  # https://man-db.nongnu.org/
  man,

  # `nix-output-monitor` is a tool for visualizing Nix output in real time.
  # https://github.com/maralorn/nix-output-monitor
  nix-output-monitor,

  # `nixfmt` is an opinionated formatter for Nix.
  # https://github.com/NixOS/nixfmt
  nixfmt,

  # `openssh` is the OpenBSD Secure Shell.
  # https://www.openssh.com/
  openssh,

  # `powerline-go` is a beautiful and useful low-latency prompt for your shell.
  # https://github.com/justjanne/powerline-go
  powerline-go,

  # `pstree` displays a tree of processes.
  # https://github.com/FredHucht/pstree
  pstree,

  # `q` is a modern dig replacement.
  # https://github.com/natesales/q
  q,

  # `qrtool` is a CLI for decoding QR codes.
  # https://github.com/sorairolake/qrtool
  qrtool,

  # `rg` is a modern `grep` written in Rust.
  # https://github.com/BurntSushi/ripgrep
  ripgrep,

  # `tailscale` is a mesh VPN built on WireGuard.
  # https://tailscale.com/
  tailscale,

  # `uutils-coreutils-noprefix` is a cross-platform reimplementation of coreutils in Rust.
  # https://github.com/uutils/coreutils
  uutils-coreutils-noprefix,

  # `vim` is the most popular clone of the vi editor.
  # https://www.vim.org/
  vim,

  # These are my customized packages (listed below)
  philiptaron,
}@args:

let
  pkgs = removeAttrs args [ "philiptaron" ] // {
    inherit (philiptaron)
      # `hyperfine` is a command-line benchmarking tool.
      # https://github.com/sharkdp/hyperfine
      hyperfine

      # `llm` is a terminal program which provides access to LLMs.
      # https://pypi.org/project/llm/
      llm

      # `nix-diff` compares Nix derivations.
      # https://github.com/Gabriella439/nix-diff
      nix-diff

      # `nix-doc` is a Nix documentation search tool.
      # https://github.com/lf-/nix-doc
      nix-doc

      # `nix-index` is a tool to quickly locate Nix packages with specific files.
      # https://github.com/nix-community/nix-index
      nix-index

      # `nix-update` is a tool to update nix packages.
      # https://github.com/Mic92/nix-update
      nix-update

      # `nix` is the purely functional package manager.
      # https://nixos.org/nix/
      nix

      # `nixpkgs-review` is a tool to review pull-requests on nixpkgs.
      # https://github.com/Mic92/nixpkgs-review
      nixpkgs-review
      ;
  };
in
builtins.attrValues pkgs
