{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  specialArgs,
}:

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

  # Set up inputrc to be my custom one.
  environment.etc.inputrc.source = dotfiles/readline/inputrc;

  # `firefox` is a web browser.
  # http://www.mozilla.com/en-US/firefox/
  programs.firefox.enable = true;

  # `htop` is an interactive process viewer.
  # https://htop.dev/
  programs.htop = {
    enable = true;
    package = pkgs.htop.overrideAttrs (
      prev: {
        # Remove the .desktop icon; no need to launch htop from Gnome.
        postInstall = ''
          rm -rf $out/share/{applications,icons,pixmaps}
        '';
      }
    );
  };

  # `wireshark` is a network packet tracing application
  # https://www.wireshark.org/
  programs.wireshark.enable = true;

  # Use Tailscale.
  services.tailscale.enable = true;

  # Turn off the firewall altogether.
  networking.firewall.enable = false;

  # Use gvfs to provide SMB and NFS mounting in GNOME (plus Trash)
  services.gvfs.enable = true;

  # Turn on polkit (ew)
  security.polkit.enable = true;

  # Turn on PCSC-Lite daemon.
  services.pcscd.enable = true;

  # Turn on sudo explicitly. In time, let's explore having other privilege escalators.
  security.sudo.enable = true;

  # Some NixOS packages provide debug symbols. However, these are not included in the system closure
  # by default to save disk space. Enabling this option causes the debug symbols to appear in
  # `/run/current-system/sw/lib/debug/.build-id`, where tools such as `gdb` can find them.
  environment.enableDebugInfo = true;

  environment.systemPackages = with pkgs; [
    # `bat` is a modern `cat` written in Rust with sweet features.
    # https://github.com/sharkdp/bat
    bat

    # `browsh` is a modern text-based browser.
    # https://www.brow.sh/
    browsh

    # `curl` is the do-anything tool for network access.
    # https://github.com/curl/curl
    curl

    # `diffoscope` tries to get to the bottom of what makes files or directories different.
    # https://diffoscope.org/
    diffoscope

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

    # `gdb` is the GNU debugger.
    # https://www.sourceware.org/gdb/
    gdb

    # `glib` is the GNOME core library
    # https://gitlab.gnome.org/GNOME/glib
    glib

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

    # `nixpkgs-fmt` is a Nix code formatter designed for nixpkgs. It's not official.
    # https://nix-community.github.io/nixpkgs-fmt
    nixpkgs-fmt

    # `nixpkgs-review` automatically builds packages changed in nixpkgs pull requests.
    # https://github.com/Mic92/nixpkgs-review
    nixpkgs-review

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

    # `uefisettings` is a rough-and-ready program to look through BIOS information in HiiDB format.
    # https://github.com/linuxboot/uefisettings
    uefisettings

    # `unzip` is an extraction utility for archives compressed in .zip format.
    # http://www.info-zip.org/
    unzip

    # The `lsusb.py`, `usbhid-dump`, `usb-devices`, and `lsusb` tools work with USB devices.
    # http://www.linux-usb.org/
    usbutils

    # `wget` is a tool for retrieving files using HTTP, HTTPS, and FTP.
    # https://www.gnu.org/software/wget/
    wget

    # `yq` is like jq for YAML files
    # https://github.com/mikefarah/yq
    yq

    # `agenix` provides `age`-encrypted secrets for NixOS
    agenix

    # `fh` connects with FlakeHub from Determinate Systems
    fh

    # `nurl` generates Nix fetcher calls from repository URLs
    nurl

    # `llama-cpp` is a set of programs for running LLMs locally
    llama-cpp
  ];

  users.users.philip.packages = with pkgs; [
    # Java web browser plugin and an implementation of Java Web Start
    adoptopenjdk-icedtea-web

    # `alacritty` is a cross-platform, GPU-accelerated terminal emulator.
    # https://github.com/alacritty/alacritty
    alacritty

    # `discord` is an all-in-one cross-platform voice and text chat for ~gamers~
    # https://discordapp.com/
    discord

    # `element-desktop` is a feature-rich client for Matrix.org
    # https://element.io/
    element-desktop

    # `gh` is the command line GitHub client.
    # https://cli.github.com/
    gh

    # Slack is the Searchable Log of All Conversation and Knowledge.
    # https://slack.com/
    slack

    # `zoom.us` is a video conferencing application.
    # https://zoom.us/
    zoom-us
  ];

  systemd.user.tmpfiles.users.philip.rules = [
    "L+ %h/.config/alacritty/alacritty.toml - - - - ${dotfiles/alacritty/alacritty.toml}"
    "L+ %h/.config/gdb/gdbinit - - - - ${dotfiles/gdb/gdbinit}"
  ];
}
