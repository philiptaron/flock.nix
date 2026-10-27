# OpenZFS from a pinned commit on master, for kernels newer than any release supports.
#
# Releases trail new kernels by months, but master gains support during the kernel's release
# candidates and declares it in META within days of the release. This builds nixpkgs' own recipe
# (generic.nix) at a master commit, so the result drops into `boot.zfs.package`, and
# `passthru.kernelModule kernelPackages` builds the matching `boot.zfs.modulePackage`.
#
# Create pools with `-o compatibility=openzfs-2.4` and never run a bare `zpool upgrade`. Then any
# 2.4 release can import them, and this package can go once a release supports the kernel.
#
# To move the pin, update `rev`, `date`, and `hash` (`nix flake prefetch github:openzfs/zfs/<rev>`),
# and `kernelMax` to META's Linux-Maximum (the build checks it), then run the ZTS shards:
#
#   nix build .#checks.x86_64-linux.pkgs-zfs-zts-sanity-{1,2,3,4}-of-4
{ pkgs, ... }:

let
  inherit (pkgs) lib;

  rev = "a128b8a075b5b13c737e56914cd7043bd3e9ebf8";
  date = "2026-10-25";
  hash = "sha256-Dsxl3YNZ7qoi2VJ4Hac1TctU8UFVEG8g5yWcQS1l8Xw=";
  kernelMax = "7.3";

  generic = "${pkgs.path}/pkgs/os-specific/linux/zfs/generic.nix";

  innerArgs = {
    version = "2.4.99-unstable-${date}";
    inherit rev hash;
    kernelModuleAttribute = "zfs_unstable";
    kernelMinSupportedMajorMinor = "4.18";
    kernelMaxSupportedMajorMinor = kernelMax;
    extraLongDescription = ''
      This is built from OpenZFS master at ${rev}.
    '';
    tests = { };
  };

  # Master moves files that generic.nix's postPatch edits, so point those edits at the new paths.
  # openzfs/zfs@0d44b58 folded libshare into libzfs.
  moved = {
    "./lib/libshare/os/linux/nfs.c" = "./lib/libzfs/os/linux/libzfs_share_nfs.c";
    "./lib/libshare/smb.h" = "./lib/libzfs/libzfs_share.h";
  };
  userspace = (pkgs.callPackage generic { configFile = "user"; } innerArgs).overrideAttrs (old: {
    # Without libudev, ZED's disk agent is compiled out: a mirror disk that comes back stays
    # REMOVED, and autoexpand never sees a disk grow. ZTS's zpool_expand tests caught this; it's
    # also NixOS/nixpkgs#570873.
    buildInputs = old.buildInputs ++ [ pkgs.systemdLibs ];

    postPatch =
      assert lib.all (path: lib.hasInfix path old.postPatch) (lib.attrNames moved);
      lib.replaceStrings (lib.attrNames moved) (lib.attrValues moved) old.postPatch;
  });

  # openzfs/zfs@e8e3076 rewrote snapshot automounting so the module no longer runs mount(8) and
  # umount(8), so generic.nix's edit pointing those at util-linux has nothing to match. Drop it.
  ctldirEdit = [
    "The arrays must remain the same length"
    "already part of the command and therefore has no effect"
    "zfs_ctldir.c"
    ''"/usr/bin/env", "umount"''
    ''"/usr/bin/env", "mount"''
  ];
  kernelModule =
    kernelPackages:
    (kernelPackages.callPackage generic {
      configFile = "kernel";
      inherit pkgs;
      inherit (kernelPackages) kernel;
    } innerArgs).overrideAttrs
      (old: {
        postPatch =
          let
            lines = lib.splitString "\n" old.postPatch;
            kept = lib.filter (line: !lib.any (part: lib.hasInfix part line) ctldirEdit) lines;
          in
          assert lib.length lines - lib.length kept == lib.length ctldirEdit;
          lib.concatStringsSep "\n" kept;
      });

  # nixpkgs deletes the installed test suite because it adds a runtime dependency on gcc. Keep it
  # in a separate build so the userspace that systems install stays as nixpkgs makes it.
  removeTests = "rm -rf $out/share/zfs/zfs-tests";
  suite = userspace.overrideAttrs (old: {
    name = "zfs-tests-${old.version}";
    # The suite builds its mmap_libaio helper only when libaio is found.
    buildInputs = old.buildInputs ++ [ pkgs.libaio ];
    # Patches for the suite only, made with `git format-patch` from the nixos-zts branch of the h
    # clone of openzfs/zfs.
    patches = old.patches ++ [
      # nixpkgs points zarcsummary at modinfo on PATH, rather than /sbin/modinfo.
      ./zts-constrained-path-modinfo.patch
      # zts-report.py's expectations come from OpenZFS CI, which builds with --enable-debug and pyzfs.
      ./zts-report-build-differences.patch
    ];
    postInstall =
      assert lib.hasInfix removeTests old.postInstall;
      lib.replaceStrings [ removeTests ] [ "" ] old.postInstall;
  });

  zts = import ./zts.nix {
    inherit pkgs zfs suite;
    # The newest kernel the pin supports, from the binary cache.
    kernelPackages = pkgs.linuxKernel.packages."linux_${lib.replaceStrings [ "." ] [ "_" ] kernelMax}";
  };

  zfs = userspace.overrideAttrs (old: {
    passthru = old.passthru // {
      inherit kernelModule suite zts;
      tests = zts.areas;
    };

    # nixpkgs lists platform patterns, but blueprint filters packages by system strings.
    meta = old.meta // {
      platforms = lib.filter (
        system: lib.any (lib.meta.platformMatch (lib.systems.elaborate system)) old.meta.platforms
      ) lib.platforms.linux;
    };
  });
in
zfs
