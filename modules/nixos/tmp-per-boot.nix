# A /tmp that is fresh on every boot but never silently deleted.
#
# Each boot creates /var/tmp-per-boot/<timestamp>/ and bind-mounts it on /tmp.
# Previous boots' directories stay where they are until pruned by hand with
# `tmp-per-boot prune`, and nothing in /tmp is aged out by systemd-tmpfiles.
# `/var/tmp-per-boot/current` always points at the live one.
#
# Anything found in the underlying /tmp before the mount (the first activation,
# or a boot where the mount somehow didn't happen) is moved into the archive as
# `pre-<timestamp>` rather than shadowed or removed.
{ pkgs, ... }:

let
  archive = "/var/tmp-per-boot";

  setup = pkgs.writeShellApplication {
    name = "tmp-per-boot-setup";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      archive=${archive}
      stamp=$(date +%Y-%m-%dT%H-%M-%S)
      mkdir -p "$archive"

      if [ -n "$(ls -A /tmp)" ]; then
        keep="$archive/pre-$stamp"
        mkdir -m 1777 "$keep"
        find /tmp -mindepth 1 -maxdepth 1 -exec mv -t "$keep" {} +
      fi

      dir="$archive/$stamp"
      mkdir -m 1777 "$dir"
      ln -sfn "$dir" "$archive/current"
    '';
  };

  cli = pkgs.writeShellApplication {
    name = "tmp-per-boot";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      archive=${archive}
      current=$(basename "$(readlink "$archive/current")")

      usage() {
        cat <<USAGE
      usage: tmp-per-boot list
             tmp-per-boot prune [--keep N]

      list   show archived /tmp directories and their sizes
      prune  delete archived /tmp directories except the current one
             (and, with --keep N, the N most recent others); needs root
      USAGE
      }

      others() {
        find "$archive" -mindepth 1 -maxdepth 1 -type d ! -name "$current" -printf '%f\n' | sort
      }

      case "''${1:-}" in
        list)
          cd "$archive"
          for d in $(others) "$current"; do
            marker=" "
            [ "$d" = "$current" ] && marker="*"
            printf '%s %8s  %s\n' "$marker" "$(du -sh "$d" | cut -f1)" "$d"
          done
          ;;
        prune)
          shift
          keep=0
          if [ "''${1:-}" = "--keep" ]; then
            keep="''${2:?--keep needs a number}"
          fi
          victims=$(others | head -n "-$keep")
          if [ -z "$victims" ]; then
            echo "nothing to prune"
            exit 0
          fi
          for d in $victims; do
            echo "removing $archive/$d"
            rm -rf "''${archive:?}/''${d:?}"
          done
          ;;
        *)
          usage
          exit 1
          ;;
      esac
    '';
  };
in
{
  systemd.services.tmp-per-boot = {
    description = "Create a fresh per-boot directory for /tmp";
    unitConfig.DefaultDependencies = false;
    before = [
      "tmp.mount"
      "local-fs.target"
    ];
    requiredBy = [ "tmp.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${setup}/bin/tmp-per-boot-setup";
    };
  };

  fileSystems."/tmp" = {
    device = "${archive}/current";
    fsType = "none";
    options = [
      "bind"
      "x-systemd.requires=tmp-per-boot.service"
      "x-systemd.after=tmp-per-boot.service"
    ];
  };

  # Replace systemd's stock tmp.conf so /tmp is never aged out. /var/tmp keeps
  # its upstream 30-day rule.
  environment.etc."tmpfiles.d/tmp.conf".text = ''
    q /tmp 1777 root root -
    q /var/tmp 1777 root root 30d
  '';

  environment.systemPackages = [ cli ];
}
