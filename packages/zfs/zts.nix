# The OpenZFS test suite (ZTS), run in NixOS VMs, one per feature area.
#
# This picks up where nixpkgs#110873 stopped: sanity.run took over 40 minutes in one VM, so it never
# fit a reasonable test budget. Here each area of the suite is its own derivation, so Nix runs them
# in parallel, caches each one by kernel and ZFS commit, and a failure names its area. Areas are
# lists of tags; each test group in common.run and linux.run is selected by its last tag, which
# names it. Tags no area lists run in `other`, so test groups that are new upstream land there.
#
# An area fails when `zfs-tests.sh` does: when a test result is unexpected per zts-report.py's
# known and maybe lists, the latter being tests known to flake. As in OpenZFS CI, there's no `-R`,
# which reruns the flaky tests and then counts their failures against the area. Logs are copied
# out to $out/test_results, but only a passing area keeps $out; for a failing one, the report at
# the end of the build log names the tests, and the interactive driver can rerun one:
#
#   nix run .#checks.x86_64-linux.pkgs-zfs-zts-kernel.driverInteractive
{
  pkgs,
  zfs,
  suite,
  kernelPackages,
}:

let
  inherit (pkgs) lib;

  # Prints the log of each test that didn't pass. They're otherwise lost with the VM when a slice
  # fails, since only a passing slice keeps $out.
  showFailures = pkgs.writeShellScript "zts-show-failures" ''
    log=$1
    dir=$(${lib.getExe' pkgs.gawk "awk"} '/^Log directory/ { print $3; exit }' "$log")
    ${lib.getExe pkgs.gnugrep} -E '\[(FAIL|KILLED|SKIP)\]' "$log" |
      ${lib.getExe pkgs.gnused} -E 's|.*Test( \([^)]*\))?: [^ ]*/functional/([^ ]+) .*|\2|' |
      while read -r test; do
        echo "=== $test"
        # test-runner writes stdout, stderr, and merged only when each has output, and names the
        # directory by the test's path below what all the run's tests share.
        ${lib.getExe pkgs.findutils} "$dir/output" -path "*/''${test##*/}/*" -type f |
          while read -r file; do
            echo "--- ''${file#"$dir/output/"}"
            cat "$file"
          done
      done
  '';

  # xxhsum picks its hash from the name it runs as, but nixpkgs installs only `xxhsum`.
  xxh128sum = pkgs.runCommand "xxh128sum" { } ''
    mkdir -p $out/bin
    ln -s ${lib.getExe pkgs.xxhash} $out/bin/xxh128sum
  '';

  # Prints the `-T` value selecting the given tags from the given runfiles, failing if one of them
  # names no test group. With `--other`, selects every tag except the given ones instead.
  selectTags = pkgs.writeShellScript "zts-select-tags" ''
    other=
    if [[ $1 == --other ]]; then
      other=1
      shift
    fi
    runfiles=$1
    shift

    all=$(
      for runfile in ''${runfiles//,/ }; do
        ${lib.getExe pkgs.gnused} -n "s/^tags = \[.*'\([^']*\)'\]$/\1/p" ${suite}/share/zfs/runfiles/$runfile
      done | ${lib.getExe' pkgs.coreutils "sort"} -u | ${lib.getExe pkgs.gnugrep} -vx functional
    )

    if [[ -n $other ]]; then
      ${lib.getExe pkgs.gnugrep} -vxF -f <(printf '%s\n' "$@") <<<"$all" | ${lib.getExe' pkgs.coreutils "paste"} -sd,
    else
      for tag; do
        if ! ${lib.getExe pkgs.gnugrep} -qxF "$tag" <<<"$all"; then
          echo "error: no test group in $runfiles is tagged $tag" >&2
          exit 1
        fi
      done
      (IFS=,; echo "$*")
    fi
  '';

  # A VM that runs the given runfiles, restricted to the `-T` value `select` prints.
  run =
    {
      name,
      runfiles,
      select,
      hours ? 2,
    }:
    pkgs.testers.runNixOSTest {
      name = "zts-${name}";
      globalTimeout = hours * 60 * 60;

      nodes.machine = {
        boot = {
          inherit kernelPackages;
          supportedFilesystems.zfs = true;
          zfs = {
            package = zfs;
            modulePackage = zfs.kernelModule kernelPackages;
          };
        };
        # NixOS's ZFS module wants a host ID, but the multihost (mmp) tests skip if /etc/hostid
        # exists; they set the host ID themselves.
        networking.hostId = "8425e349";
        environment.etc.hostid.enable = false;

        # The fault and expansion tests start their own ZED, and fail if one is already running.
        systemd.services.zfs-zed.enable = false;

        # The share tests run exportfs, which needs the NFS server's state in /var/lib/nfs.
        services.nfs.server.enable = true;

        # mount_loopback looks for XFS in /lib/modules, which NixOS doesn't have, or in
        # /proc/filesystems, which lists it once the module is loaded.
        boot.kernelModules = [ "xfs" ];

        # The size of one of CI's VMs. The file vdevs are sparse, so the disk only grows as far
        # as the tests write.
        virtualisation = {
          cores = 2;
          memorySize = 8192;
          diskSize = 32768;
        };

        # zfs-tests.sh refuses to run as root, and runs the tests through passwordless sudo.
        users.users.zts = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
        security.sudo.wheelNeedsPassword = false;

        # zfs-tests.sh links the commands the tests may use into a constrained PATH, but looks for
        # them only in /usr/local/bin, /usr/local/sbin, /usr/bin, /usr/sbin, /bin, and /sbin, in
        # that order. Point the first at the setuid wrappers so `sudo` is the real one, and the
        # rest at the system profile. The tests' interpreter is /bin/ksh, and some mount on /mnt.
        systemd.tmpfiles.rules = [
          "L+ /usr/local/bin - - - - /run/wrappers/bin"
          "L+ /usr/local/sbin - - - - /run/current-system/sw/bin"
          "L+ /sbin - - - - /run/current-system/sw/bin"
          "L+ /bin/ksh - - - - ${lib.getExe pkgs.ksh}"
          # xattrtest's default hook after each phase.
          "L+ /bin/true - - - - ${lib.getExe' pkgs.coreutils "true"}"
          # What libzfs runs to mount and unmount when ZFS_MOUNT_HELPER is set.
          "L+ /bin/mount - - - - ${lib.getExe' pkgs.util-linux "mount"}"
          "L+ /bin/umount - - - - ${lib.getExe' pkgs.util-linux "umount"}"
          # The idmapped mount tests anchor a user namespace with /usr/bin/sleep, and the
          # auto_replace tests run /usr/sbin/wipefs.
          "L+ /usr/bin/sleep - - - - ${lib.getExe' pkgs.coreutils "sleep"}"
          "d /usr/sbin 0755 root root -"
          "L+ /usr/sbin/wipefs - - - - ${lib.getExe' pkgs.util-linux "wipefs"}"
          # The io_uring tests look for CONFIG_IO_URING=y in the running kernel's config.
          "d /boot 0755 root root -"
          "L+ /boot/config-${kernelPackages.kernel.modDirVersion} - - - - ${kernelPackages.kernel.configfile}"
          "d /mnt 0755 root root -"
          # Some tests copy /usr/share/dict as sample data.
          "d /usr/share 0755 root root -"
          "L+ /usr/share/dict - - - - ${pkgs.scowl}/share/dict"
        ];

        # The commands in tests/zfs-tests/include/commands.cfg that NixOS doesn't already have.
        # `net` (Samba) is left out; the SMB share tests skip without it.
        environment.systemPackages = with pkgs; [
          acl
          attr
          bc
          binutils
          cpio
          cryptsetup
          e2fsprogs
          fio
          file
          getconf
          getent
          glibc.bin
          hostname
          jq
          perf
          ksh
          libcap
          lsscsi
          nfs-utils
          openssl
          pamtester
          parted
          pax
          python3
          rsync
          sysstat
          which
          xfsprogs
          xxh128sum
        ];
      };

      testScript = ''
        machine.wait_for_unit("multi-user.target")
        machine.succeed("modprobe zfs")

        tags = machine.succeed("${select}").strip()
        if not tags:
            print("No test groups to run.")
        else:
            print(f"Tags: {tags}")
            status, _ = machine.execute(
                "runuser -u zts -- ${suite}/share/zfs/zfs-tests.sh -vKO -s 3G"
                + f" -r ${runfiles} -T {tags}"
                + " >/var/tmp/zts.log 2>&1",
                timeout=None,
            )

            print(machine.succeed("grep -E '^(Missing util|Log directory)' /var/tmp/zts.log || true"))
            print(machine.succeed("sed -n '/^Results Summary/,$p' /var/tmp/zts.log"))
            print(machine.succeed("${showFailures} /var/tmp/zts.log"))
            # `current` is an absolute symlink to the newest run, dangling outside the VM.
            machine.succeed("mkdir -p /var/tmp/test_results && cp /var/tmp/zts.log /var/tmp/test_results/")
            machine.succeed("rm -f /var/tmp/test_results/current")
            machine.copy_from_machine("/var/tmp/test_results", "")

            assert status == 0, f"zfs-tests.sh exited {status}"
      '';
    };

  # Areas of common.run and linux.run, sized at 10 to 30 minutes by the durations in zfs-tests.sh.
  areas = {
    # Where ZFS meets the kernel's VFS and block layers, so where a new kernel breaks it.
    kernel.tags = [
      "acl"
      "append"
      "atime"
      "casenorm"
      "chattr"
      "cp_files"
      "crtime"
      "ctime"
      "device_access"
      "devices"
      "direct"
      "dos_attributes"
      "exec"
      "fadvise"
      "fallocate"
      "getfsuuid"
      "idmap_mount"
      "io"
      "lease"
      "limits"
      "link_count"
      "longname"
      "luks"
      "mmap"
      "mv_files"
      "posix"
      "posix-sa"
      "procfs"
      "rename_dirs"
      "renameat2"
      "sparse"
      "stat"
      "suid"
      "syncfs"
      "tmpfile"
      "truncate"
      "uncached"
      "unlink"
      "user_namespace"
      "vdev_disk"
      "write_dirs"
      "xattr"
      "zoned_uid"
      "zvol_ENOSPC"
      "zvol_cli"
      "zvol_misc"
      "zvol_stress"
      "zvol_swap"
    ];
    pool-lifecycle.tags = [
      "bootfs"
      "cachefile"
      "inuse"
      "json"
      "pool_names"
      "poolversion"
      "rootpool"
      "upgrade"
      "zpool"
      "zpool_add"
      "zpool_clear"
      "zpool_create"
      "zpool_destroy"
      "zpool_events"
      "zpool_export"
      "zpool_get"
      "zpool_history"
      "zpool_import"
      "zpool_influxdb"
      "zpool_iostat"
      "zpool_labelclear"
      "zpool_list"
      "zpool_reguid"
      "zpool_set"
      "zpool_status"
      "zpool_sync"
      "zpool_upgrade"
    ];
    pool-maintenance.tags = [
      "clean_mirror"
      "grow"
      "pool_checkpoint"
      "removal"
      "scrub_mirror"
      "trim"
      "zpool_condense"
      "zpool_expand"
      "zpool_initialize"
      "zpool_prefetch"
      "zpool_remove"
      "zpool_scrub"
      "zpool_trim"
      "zpool_wait"
    ];
    pool-internals.tags = [
      "arc"
      "btree"
      "cache"
      "checksum"
      "compression"
      "deadman"
      "failmode"
      "gang_blocks"
      "hkdf"
      "large_dnode"
      "large_files"
      "largest_pool"
      "libzfs"
      "log_spacemap"
      "lua_core"
      "no_space"
      "simd"
      "synctask_core"
      "test_runner"
      "vdev_zaps"
      "zap_shrink"
      "zdb"
      "zhack"
      "zinject"
    ];
    datasets.tags = [
      "async_destroy"
      "delegate"
      "history"
      "inheritance"
      "migration"
      "misc"
      "mount"
      "nestedfs"
      "nopwrite"
      "pam"
      "projectquota"
      "quota"
      "refquota"
      "refreserv"
      "reservation"
      "snapdir"
      "snapshot"
      "snapused"
      "userquota"
      "zfs"
      "zfs_clone"
      "zfs_copies"
      "zfs_create"
      "zfs_destroy"
      "zfs_diff"
      "zfs_get"
      "zfs_ids_to_path"
      "zfs_inherit"
      "zfs_list"
      "zfs_mount"
      "zfs_program"
      "zfs_promote"
      "zfs_property"
      "zfs_rename"
      "zfs_reservation"
      "zfs_rewrite"
      "zfs_rollback"
      "zfs_set"
      "zfs_snapshot"
      "zfs_sysfs"
      "zfs_unmount"
      "zfs_upgrade"
      "zfs_wait"
    ];
    resilver.tags = [
      "online_offline"
      "replacement"
      "zpool_attach"
      "zpool_detach"
      "zpool_offline"
      "zpool_online"
      "zpool_reopen"
      "zpool_replace"
      "zpool_resilver"
      "zpool_split"
    ];
    zed.tags = [
      "events"
      "fault"
    ];
    send-recv.tags = [
      "redacted_send"
      "rsend"
      "send_xdr_encoding"
      "zfs_bookmark"
      "zfs_receive"
      "zfs_send"
      "zstream"
    ];
    vdev-classes.tags = [
      "alloc_class"
      "l2arc"
      "slog"
    ];
    cloning-dedup.tags = [
      "bclone"
      "block_cloning"
      "dedup"
    ];
    raidz-draid.tags = [
      "raidz"
      "redundancy"
    ];
    multihost.tags = [ "mmp" ];
    sharing.tags = [
      "zfs_share"
      "zfs_unshare"
    ];
    encryption.tags = [
      "crypto"
      "zfs_change-key"
      "zfs_load-key"
      "zfs_unload-key"
    ];
  };

  runfiles = "common.run,linux.run";

  # Each area's test, plus `other`.
  testsFor =
    selected:
    lib.mapAttrs' (
      name: area:
      lib.nameValuePair "zts-${name}" (run {
        inherit name runfiles;
        select = "${selectTags} ${runfiles} ${lib.escapeShellArgs area.tags}";
      })
    ) selected
    // {
      zts-other = run {
        name = "other";
        inherit runfiles;
        select = "${selectTags} --other ${runfiles} ${
          lib.escapeShellArgs (lib.concatMap (area: area.tags) (lib.attrValues areas))
        }";
      };
    };
in
{
  # The quick suite OpenZFS CI runs for small changes, in four slices of about equal run time.
  sanity = lib.listToAttrs (
    map (
      index:
      lib.nameValuePair "zts-sanity-${toString index}-of-4" (run {
        name = "sanity-${toString index}-of-4";
        runfiles = "sanity.run";
        select = "echo ${toString index}/4";
      })
    ) (lib.range 1 4)
  );

  # The given test groups, by tag, in one VM: to rerun a few of them.
  tagged =
    tags:
    run {
      name = "tagged-${lib.concatStringsSep "-" tags}";
      inherit runfiles;
      select = "${selectTags} ${runfiles} ${lib.escapeShellArgs tags}";
    };

  # Every area, and `other`: the package's passthru.tests.
  areas = testsFor areas;
}
