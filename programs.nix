{ config, pkgs, inputs, ... }:

{
  # Use Vim as the editor of choice.
  programs.vim.defaultEditor = true;

  # Have an SSH agent.
  programs.ssh.startAgent = true;

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

  environment.systemPackages = with pkgs; [
    # `bat` is a modern `cat` written in Rust with sweet features.
    # https://github.com/sharkdp/bat
    bat

    # `curl` is the do-anything tool for network access.
    # https://github.com/curl/curl
    curl

    # `fd` is a simple, fast and user-friendly alternative to find.
    # https://github.com/sharkdp/fd
    fd

    # `file` is a program that shows the type of files.
    # https://darwinsys.com/file
    file

    # `git` is a distributed version control system.
    # https://git-scm.com/
    git

    # The `fixparts`, `cgdisk`, `sgdisk`, and `gdisk` programs are partitioning tools for GPT disks.
    # https://www.rodsbooks.com/gdisk/
    gptfdisk

    # `iw` is a new nl80211 based CLI configuration utility for wireless devices.
    # https://wireless.wiki.kernel.org/en/users/Documentation/iw
    iw

    # `jq` is a lightweight and flexible command-line JSON processor.
    # https://stedolan.github.io/jq/
    jq

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

    # `unzip` is an extraction utility for archives compressed in .zip format.
    # http://www.info-zip.org/
    unzip

    # The `lsusb.py`, `usbhid-dump`, `usb-devices`, and `lsusb` tools work with USB devices.
    # http://www.linux-usb.org/
    usbutils

    # `wget` is a tool for retrieving files using HTTP, HTTPS, and FTP.
    # https://www.gnu.org/software/wget/
    wget

    # `agenix` provides `age`-encrypted secrets for NixOS
    inputs.agenix.packages."${system}".default
  ];

  users.users.philip.packages = with pkgs; [
    # `alacritty` is a cross-platform, GPU-accelerated terminal emulator.
    # https://github.com/alacritty/alacritty
    alacritty

    # `figlet` is a program for making large letters out of ordinary text.
    # http://www.figlet.org/
    figlet

    # `firefox` is a web browser.
    # http://www.mozilla.com/en-US/firefox/
    firefox

    # Utility used in the GNOME desktop environment for taking screenshots
    # https://gitlab.gnome.org/GNOME/gnome-screenshot
    gnome.gnome-screenshot

    # A simple app icon taskbar. Show running apps and favorites on the main panel.
    # https://extensions.gnome.org/extension/4944/app-icons-taskbar/
    gnomeExtensions.app-icons-taskbar

    # Adds a clock to the desktop.
    # https://extensions.gnome.org/extension/5156/desktop-clock/
    gnomeExtensions.desktop-clock

    # Move clock to left of status menu button
    # https://extensions.gnome.org/extension/2/move-clock/
    gnomeExtensions.move-clock

    # Allows the customization of the date format on the Gnome panel.
    # https://extensions.gnome.org/extension/3465/panel-date-format/
    gnomeExtensions.panel-date-format-2

    # `gping` is ping, but with a graph.
    # https://github.com/orf/gping
    gping

    # `hexyl` is a command-line hex viewer.
    # https://github.com/sharkdp/hexyl
    hexyl

    # `nixpkgs-fmt` is a Nix code formatter for nixpkgs.
    # https://nix-community.github.io/nixpkgs-fmt
    nixpkgs-fmt

    # Slack is the Searchable Log of All Conversation and Knowledge.
    # https://slack.com/
    slack

    # `zoom.us` is a video conferencing application.
    zoom-us
  ];
}
