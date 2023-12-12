{ config, pkgs, inputs, ... }:

{
  # Use Vim as the editor of choice.
  programs.vim.defaultEditor = true;

  # Have an SSH agent.
  programs.ssh.startAgent = true;

  # Make bash history not forget things so often.
  programs.bash.interactiveShellInit = ''
    HISTSIZE=10000000
    HISTFILESIZE=100000000
  '';

  # `firefox` is a web browser.
  # http://www.mozilla.com/en-US/firefox/
  programs.firefox.enable = true;

  # `htop` is an interactive process viewer.
  # https://htop.dev/
  programs.htop = {
    enable = true;
    package = pkgs.htop.overrideAttrs (prev: {
      # Remove the .desktop icon; no need to launch htop from Gnome.
      postInstall = ''
        rm -rf $out/share/{applications,icons,pixmaps}
      '';
    });
  };

  # Use Tailscale.
  services.tailscale.enable = true;

  # Turn off the firewall altogether.
  networking.firewall.enable = false;

  # Turn on polkit (ew)
  security.polkit.enable = true;

  # Turn on sudo explicitly. In time, let's explore having other privilege escalators.
  security.sudo.enable = true;

  environment.systemPackages = with pkgs; [
    # `bat` is a modern `cat` written in Rust with sweet features.
    # https://github.com/sharkdp/bat
    bat

    # `curl` is the do-anything tool for network access.
    # https://github.com/curl/curl
    curl

    # `efibootmgr` is a tool to control EFI boots
    # https://github.com/rhboot/efibootmgr/
    efibootmgr

    # `efivar` is a tool to show and modify EFI variables
    # https://github.com/rhboot/efivar
    efivar

    # `fd` is a simple, fast and user-friendly alternative to find.
    # https://github.com/sharkdp/fd
    fd

    # `figlet` is a program for making large letters out of ordinary text.
    # http://www.figlet.org/
    figlet

    # `file` is a program that shows the type of files.
    # https://darwinsys.com/file
    file

    # `frogmouth` is a text markdown viewer and browser.
    # https://github.com/Textualize/frogmouth
    frogmouth

    # `git` is a distributed version control system.
    # https://git-scm.com/
    git

    # `git-lfs` is used to distribute large files with Git.
    # https://git-lfs.github.com/
    git-lfs

    # `gping` is ping, but with a graph.
    # https://github.com/orf/gping
    gping

    # The `fixparts`, `cgdisk`, `sgdisk`, and `gdisk` programs are partitioning tools for GPT disks.
    # https://www.rodsbooks.com/gdisk/
    gptfdisk

    # `hexyl` is a command-line hex viewer.
    # https://github.com/sharkdp/hexyl
    hexyl

    # `jq` is a lightweight and flexible command-line JSON processor.
    # https://stedolan.github.io/jq/
    jq

    # `nixpkgs-fmt` is a Nix code formatter for nixpkgs.
    # https://nix-community.github.io/nixpkgs-fmt
    nixpkgs-fmt

    # `lspci` and `setpci` are tools that inspect and manipulate the configuration of PCI devices.
    # https://mj.ucw.cz/sw/pciutils/
    pciutils

    # `pv` is a tool for monitoring the progress of data through a pipeline.
    # https://www.ivarch.com/programs/pv.shtml
    pv

    # `rg` is a modern `grep` written in Rust.
    # https://github.com/BurntSushi/ripgrep
    ripgrep

    # The `rdsquashfs`, `tar2sqfs`, `sqfsdiff`, `gensquashfs`, and `sqfs2tar` tools work on #
    # SquashFS disk images.
    # https://github.com/AgentD/squashfs-tools-ng
    squashfs-tools-ng

    # A collection of performance monitoring tools for Linux (such as `sar`, `iostat` and `pidstat`)
    # http://sebastien.godard.pagesperso-orange.fr/
    sysstat

    # `unzip` is an extraction utility for archives compressed in .zip format.
    # http://www.info-zip.org/
    unzip

    # The `lsusb.py`, `usbhid-dump`, `usb-devices`, and `lsusb` tools work with USB devices.
    # http://www.linux-usb.org/
    usbutils

    # `wget` is a tool for retrieving files using HTTP, HTTPS, and FTP.
    # https://www.gnu.org/software/wget/
    wget

    # `xq` is like jq for XML files
    # https://github.com/sibprogrammer/xq
    xq

    # `yq` is like jq for YAML files
    # https://github.com/mikefarah/yq
    yq

    # `agenix` provides `age`-encrypted secrets for NixOS
    inputs.agenix.packages."${system}".default

    # `fh` connects with FlakeHub from Determinate Systems
    inputs.fh.packages."${system}".default
  ];

  users.users.philip.packages = with pkgs; [
    # `alacritty` is a cross-platform, GPU-accelerated terminal emulator.
    # https://github.com/alacritty/alacritty
    alacritty

    # `discord` is an all-in-one cross-platform voice and text chat for ~gamers~
    # https://discordapp.com/
    discord

    # `element-desktop` is a feature-rich client for Matrix.org
    # https://element.io/
    element-desktop

    # Slack is the Searchable Log of All Conversation and Knowledge.
    # https://slack.com/
    slack

    # `zoom.us` is a video conferencing application.
    # https://zoom.us/
    zoom-us
  ];
}
