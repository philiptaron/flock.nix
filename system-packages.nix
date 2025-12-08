{
  # `bat` is a modern `cat` written in Rust with sweet features.
  # https://github.com/sharkdp/bat
  bat,

  # `browsh` is a modern text-based browser.
  # https://www.brow.sh/
  browsh,

  # `curl` is the do-anything tool for network access.
  # https://github.com/curl/curl
  curl,

  # `diffoscope` tries to get to the bottom of what makes files or directories different.
  # https://diffoscope.org/
  diffoscope,

  # `dutree` is a tool to analyze file system usage written in Rust
  # https://github.com/nachoparker/dutree
  dutree,

  # `efibootmgr` is a tool to control EFI boots
  # https://github.com/rhboot/efibootmgr/
  efibootmgr,

  # `efivar` is a tool to show and modify EFI variables
  # https://github.com/rhboot/efivar
  efivar,

  # `erd` is a file-tree visualizer and disk usage analyzer
  # https://github.com/solidiquis/erdtree
  erdtree,

  # `fastfetch` displays an infographic about the current system to the terminal.
  # https://github.com/fastfetch-cli/fastfetch
  fastfetch,

  # `fd` is a simple, fast and user-friendly alternative to find.
  # https://github.com/sharkdp/fd
  fd,

  # `figlet` is a program for making large letters out of ordinary text.
  # http://www.figlet.org/
  figlet,

  # `file` is a program that shows the type of files.
  # https://darwinsys.com/file
  file,

  # `ffmpeg` is a audio-visual toolkit to do roughly everything.
  # https://www.ffmpeg.org/
  ffmpeg,

  # `gdb` is the GNU debugger.
  # https://www.sourceware.org/gdb/
  gdb,

  # `gh` is the command line GitHub client.
  # https://cli.github.com/
  gh,

  # `glib` is the GNOME core library
  # https://gitlab.gnome.org/GNOME/glib
  glib,

  # `gping` is ping, but with a graph.
  # https://github.com/orf/gping
  gping,

  # The `fixparts`, `cgdisk`, `sgdisk`, and `gdisk` programs are partitioning tools for GPT disks.
  # https://www.rodsbooks.com/gdisk/
  gptfdisk,

  # `hexyl` is a command-line hex viewer.
  # https://github.com/sharkdp/hexyl
  hexyl,

  # `inotifywait`, `fsnotifywatch`, `inotifywatch`, and `fsnotifywait` allow waiting for
  # filesystem events and running commands when they occur.
  # https://github.com/inotify-tools/inotify-tools/wiki
  inotify-tools,

  # `jq` is a lightweight and flexible command-line JSON processor.
  # https://stedolan.github.io/jq/
  jq,

  # `llama-cpp` is a set of programs for running LLMs locally
  # https://github.com/ggml-org/llama.cpp
  llama-cpp,

  # `moreutils` is a collection of unix tools that nobody thought to write when unix was young
  # https://joeyh.name/code/moreutils/
  moreutils,

  # `lspci` and `setpci` are tools that inspect and manipulate the configuration of PCI devices.
  # https://mj.ucw.cz/sw/pciutils/
  pciutils,

  # `pv` is a tool for monitoring the progress of data through a pipeline.
  # https://www.ivarch.com/programs/pv.shtml
  pv,

  # `q` is a modern dig replacement
  # https://github.com/natesales/q
  q,

  # `qrtool` is a CLI for decoding QR codes
  # https://github.com/sorairolake/qrtool
  qrtool,

  # `ren` is a file rename tool that fits in with `fd`.
  # https://blog.robenkleene.com/2023/12/26/introducing-rep-ren/
  ren-find,

  # `rep` is a find-and-replace tool that fits in with `rg`
  # https://blog.robenkleene.com/2023/12/26/introducing-rep-ren/
  rep-grep,

  # `rg` is a modern `grep` written in Rust.
  # https://github.com/BurntSushi/ripgrep
  ripgrep,

  # `shellcheck` is a static analysis tool for Bash shell scripts.
  # https://www.shellcheck.net/
  shellcheck,

  # `shfmt` is a shell formatter (sh/bash/mksh).
  # https://github.com/mvdan/sh
  shfmt,

  # The `rdsquashfs`, `tar2sqfs`, `sqfsdiff`, `gensquashfs`, and `sqfs2tar` tools work on
  # SquashFS disk images.
  # https://github.com/AgentD/squashfs-tools-ng
  squashfs-tools-ng,

  # A collection of performance monitoring tools for Linux (such as `sar`, `iostat` and `pidstat`)
  # http://sebastien.godard.pagesperso-orange.fr/
  sysstat,

  # `uefisettings` is a rough-and-ready program to look through BIOS information in HiiDB format.
  # https://github.com/linuxboot/uefisettings
  uefisettings,

  # `unzip` is an extraction utility for archives compressed in .zip format.
  # http://www.info-zip.org/
  unzip,

  # The `lsusb.py`, `usbhid-dump`, `usb-devices`, and `lsusb` tools work with USB devices.
  # http://www.linux-usb.org/
  usbutils,

  # `watchexec` is a tool to execute something when files change.
  # https://watchexec.github.io/
  watchexec,

  # `wget` is a tool for retrieving files using HTTP, HTTPS, and FTP.
  # https://www.gnu.org/software/wget/
  wget,

  # `yq` is like jq for YAML files
  # https://github.com/mikefarah/yq
  yq,

  # These are my customized packages (listed below)
  philiptaron,
}@args:

let
  pkgs = removeAttrs args [ "philiptaron" ] // {
    inherit (philiptaron)
      # `btop` monitors system resources.
      # https://github.com/aristocratos/btop
      btop

      # `htop` is an interactive process viewer.
      # https://htop.dev/
      htop

      # `hyperfine` is a command-line benchmarking tool
      # https://github.com/sharkdp/hyperfine
      hyperfine

      # `llm` is a terminal program which provides access to LLMs.
      # https://pypi.org/project/llm/
      llm
      ;
  };
in
builtins.attrValues pkgs
