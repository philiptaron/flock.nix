{ pkgs, ... }:

{
  # Use Vim as the editor of choice.
  programs.vim.enable = true;
  programs.vim.defaultEditor = true;

  # `firefox` is a web browser.
  # http://www.mozilla.com/en-US/firefox/
  programs.firefox.enable = true;

  # `htop` is an interactive process viewer.
  # https://htop.dev/
  programs.htop.enable = true;
  programs.htop.package = pkgs.philiptaron.htop;

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

  environment.systemPackages = [
    # `bat` is a modern `cat` written in Rust with sweet features.
    # https://github.com/sharkdp/bat
    pkgs.bat

    # `browsh` is a modern text-based browser.
    # https://www.brow.sh/
    pkgs.browsh

    # `btop` monitors system resources.
    # https://github.com/aristocratos/btop
    pkgs.philiptaron.btop

    # `curl` is the do-anything tool for network access.
    # https://github.com/curl/curl
    pkgs.curl

    # `diffoscope` tries to get to the bottom of what makes files or directories different.
    # https://diffoscope.org/
    pkgs.diffoscope

    # `dutree` is a tool to analyze file system usage written in Rust
    # https://github.com/nachoparker/dutree
    pkgs.dutree

    # `efibootmgr` is a tool to control EFI boots
    # https://github.com/rhboot/efibootmgr/
    pkgs.efibootmgr

    # `efivar` is a tool to show and modify EFI variables
    # https://github.com/rhboot/efivar
    pkgs.efivar

    # `fd` is a simple, fast and user-friendly alternative to find.
    # https://github.com/sharkdp/fd
    pkgs.fd

    # `figlet` is a program for making large letters out of ordinary text.
    # http://www.figlet.org/
    pkgs.figlet

    # `file` is a program that shows the type of files.
    # https://darwinsys.com/file
    pkgs.file

    # `ffmpeg` is a audio-visual toolkit to do roughly everything.
    # https://www.ffmpeg.org/
    pkgs.ffmpeg

    # `gdb` is the GNU debugger.
    # https://www.sourceware.org/gdb/
    pkgs.gdb

    # `gh` is the command line GitHub client.
    # https://cli.github.com/
    pkgs.gh

    # `glib` is the GNOME core library
    # https://gitlab.gnome.org/GNOME/glib
    pkgs.glib

    # `gping` is ping, but with a graph.
    # https://github.com/orf/gping
    pkgs.gping

    # The `fixparts`, `cgdisk`, `sgdisk`, and `gdisk` programs are partitioning tools for GPT disks.
    # https://www.rodsbooks.com/gdisk/
    pkgs.gptfdisk

    # `hexyl` is a command-line hex viewer.
    # https://github.com/sharkdp/hexyl
    pkgs.hexyl

    # `hyperfine` is a command-line benchmarking tool
    # https://github.com/sharkdp/hyperfine
    pkgs.philiptaron.hyperfine

    # `inotifywait`, `fsnotifywatch`, `inotifywatch`, and `fsnotifywait` allow waiting for
    # filesystem events and running commands when they occur.
    # https://github.com/inotify-tools/inotify-tools/wiki
    pkgs.inotify-tools

    # `jq` is a lightweight and flexible command-line JSON processor.
    # https://stedolan.github.io/jq/
    pkgs.jq

    # `llm` is a terminal program which provides access to LLMs.
    # https://pypi.org/project/llm/
    pkgs.philiptaron.llm

    # `moreutils` is a collection of unix tools that nobody thought to write when unix was young
    # https://joeyh.name/code/moreutils/
    pkgs.moreutils

    # `lspci` and `setpci` are tools that inspect and manipulate the configuration of PCI devices.
    # https://mj.ucw.cz/sw/pciutils/
    pkgs.pciutils

    # `pv` is a tool for monitoring the progress of data through a pipeline.
    # https://www.ivarch.com/programs/pv.shtml
    pkgs.pv

    # `q` is a modern dig replacement
    # https://github.com/natesales/q
    pkgs.q

    # `qrtool` is a CLI for decoding QR codes
    # https://github.com/sorairolake/qrtool
    pkgs.qrtool

    # `ren` is a file rename tool that fits in with `fd`.
    # https://blog.robenkleene.com/2023/12/26/introducing-rep-ren/
    pkgs.ren-find

    # `rep` is a find-and-replace tool that fits in with `rg`
    # https://blog.robenkleene.com/2023/12/26/introducing-rep-ren/
    pkgs.rep-grep

    # `rg` is a modern `grep` written in Rust.
    # https://github.com/BurntSushi/ripgrep
    pkgs.ripgrep

    # `shellcheck` is a static analysis tool for Bash shell scripts.
    # https://www.shellcheck.net/
    pkgs.shellcheck

    # `shfmt` is a shell formatter (sh/bash/mksh).
    # https://github.com/mvdan/sh
    pkgs.shfmt

    # The `rdsquashfs`, `tar2sqfs`, `sqfsdiff`, `gensquashfs`, and `sqfs2tar` tools work on
    # SquashFS disk images.
    # https://github.com/AgentD/squashfs-tools-ng
    pkgs.squashfs-tools-ng

    # A collection of performance monitoring tools for Linux (such as `sar`, `iostat` and `pidstat`)
    # http://sebastien.godard.pagesperso-orange.fr/
    pkgs.sysstat

    # `uefisettings` is a rough-and-ready program to look through BIOS information in HiiDB format.
    # https://github.com/linuxboot/uefisettings
    pkgs.uefisettings

    # `unzip` is an extraction utility for archives compressed in .zip format.
    # http://www.info-zip.org/
    pkgs.unzip

    # The `lsusb.py`, `usbhid-dump`, `usb-devices`, and `lsusb` tools work with USB devices.
    # http://www.linux-usb.org/
    pkgs.usbutils

    # `watchexec` is a tool to execute something when files change.
    # https://watchexec.github.io/
    pkgs.watchexec

    # `wget` is a tool for retrieving files using HTTP, HTTPS, and FTP.
    # https://www.gnu.org/software/wget/
    pkgs.wget

    # `yq` is like jq for YAML files
    # https://github.com/mikefarah/yq
    pkgs.yq

    # `llama-cpp` is a set of programs for running LLMs locally
    pkgs.llama-cpp
  ];

  users.users.philip.packages = [
    # `codex` is a terminal agent for the GPT series of models from OpenAI.
    # https://openai.com/codex
    pkgs.codex

    # `claude` is a terminal agent for the Opus and Sonnet series of models from Anthropic.
    # https://www.claude.com/product/claude-code
    pkgs.claude-code

    # `gemini` is a terminal agent for the Gemini series of models from Google.
    # https://github.com/google-gemini/gemini-cli
    pkgs.gemini-cli

    # `alacritty` is a cross-platform, GPU-accelerated terminal emulator.
    # https://github.com/alacritty/alacritty
    pkgs.philiptaron.alacritty

    # FluffyChat is an open source, nonprofit and cute Matrix client written in Flutter.
    # https://github.com/krille-chan/fluffychat
    pkgs.fluffychat

    # `ghostty` is a new terminal emulator from Mitchell Hashimoto.
    # https://ghostty.org/
    pkgs.ghostty

    # `chromium` is a browser from Google.
    # https://www.chromium.org/
    pkgs.chromium

    # `discord` is an all-in-one cross-platform voice and text chat for ~gamers~
    # https://discordapp.com/
    pkgs.discord

    # `gh` is the command line GitHub client.
    # https://cli.github.com/
    pkgs.gh

    # `signal` is the Signal secure messaging client.
    # https://signal.org/
    pkgs.signal-desktop

    # Slack is the Searchable Log of All Conversation and Knowledge.
    # https://slack.com/
    pkgs.slack

    # Zoom is a cloud-based video communications platform that enables virtual meetings, webinars,
    # messaging, and collaboration across devices.
    # https://zoom.us/
    pkgs.zoom-us

    # Zulip is organized chat for distributed teams
    # https://zulip.com/
    pkgs.zulip
  ];

  systemd.user.tmpfiles.users.philip.rules = [
    "L+ %h/.config/alacritty/alacritty.toml - - - - ${dotfiles/alacritty/alacritty.toml}"
    "L+ %h/.config/gdb/gdbinit - - - - ${dotfiles/gdb/gdbinit}"
  ];
}
