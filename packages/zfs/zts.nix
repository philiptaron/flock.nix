# The OpenZFS test suite (ZTS), run in NixOS VMs and sharded so each VM runs a slice.
#
# This picks up where nixpkgs#110873 stopped: sanity.run took over 40 minutes in one VM, so it never
# fit a reasonable test budget. `zfs-tests.sh -T i/N` splits a run into N slices of about equal
# run time (by its own table of test durations), and each slice here is its own derivation, so Nix
# runs them in parallel and caches each one by kernel and ZFS commit.
#
# A slice fails when `zfs-tests.sh` does: when a test result is unexpected per zts-report.py's
# known and maybe lists. `-R` reruns the maybes first, so flaky tests don't fail a slice. Logs are
# copied out to $out/test_results, but only a passing slice keeps $out; for a failing one, the
# report at the end of the build log names the tests, and the interactive driver can rerun one:
#
#   nix run .#checks.x86_64-linux.pkgs-zfs-zts-sanity-1-of-4.driverInteractive
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
      ${lib.getExe pkgs.gnused} -E 's|.*Test: [^ ]*/functional/([^ ]+) .*|\1|' |
      while read -r test; do
        echo "=== $test"
        ${lib.getExe pkgs.findutils} "$dir/output" -path "*/$test/merged" -exec cat {} +
      done
  '';

  # xxhsum picks its hash from the name it runs as, but nixpkgs installs only `xxhsum`.
  xxh128sum = pkgs.runCommand "xxh128sum" { } ''
    mkdir -p $out/bin
    ln -s ${lib.getExe pkgs.xxhash} $out/bin/xxh128sum
  '';

  sliceName =
    {
      name,
      index,
      count,
    }:
    "zts-${name}-${toString index}-of-${toString count}";

  slice =
    {
      name,
      runfiles,
      index,
      count,
      hours,
    }:
    pkgs.testers.runNixOSTest {
      name = sliceName { inherit name index count; };
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
        networking.hostId = "8425e349";

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
          "d /mnt 0755 root root -"
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
          kernelPackages.perf
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

        status, _ = machine.execute(
            "runuser -u zts -- ${suite}/share/zfs/zfs-tests.sh -vKOR -s 3G"
            + " -r ${runfiles} -T ${toString index}/${toString count}"
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

  slices =
    {
      name,
      runfiles,
      count,
      hours,
    }:
    lib.listToAttrs (
      map (
        index:
        lib.nameValuePair (sliceName { inherit name index count; }) (slice {
          inherit
            name
            runfiles
            index
            count
            hours
            ;
        })
      ) (lib.range 1 count)
    );
in
{
  # The quick suite OpenZFS CI runs for small changes.
  sanity = slices {
    name = "sanity";
    runfiles = "sanity.run";
    count = 4;
    hours = 2;
  };
}
