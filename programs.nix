{ config, pkgs, inputs, ... }:

{
  # Use Vim as the editor of choice.
  programs.vim.defaultEditor = true;

  # Have an SSH agent
  programs.ssh.startAgent = true;

  # Use tailscale
  services.tailscale.enable = true;

  # Turn off the firewall altogether.
  networking.firewall.enable = false;

  environment.systemPackages = with pkgs; [
    bat
    curl
    fd
    file
    git
    gptfdisk
    htop
    iw
    jq
    pv
    ripgrep
    squashfs-tools-ng
    unzip
    usbutils
    wget
    inputs.agenix.packages."${system}".default
  ];

  users.users.philip.packages = with pkgs; [
    alacritty
    anydesk
    figlet
    firefox
    gnome.dconf-editor
    gnome.gnome-screenshot
    gnomeExtensions.app-icons-taskbar
    gnomeExtensions.desktop-clock
    gnomeExtensions.move-clock
    gnomeExtensions.panel-date-format-2
    gping
    hexyl
    neofetch
    nixpkgs-fmt
    slack
    webex
    zoom-us
  ];
}
