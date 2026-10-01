# Keep the shared git object stores fresh.
#
# `h` (https://github.com/philiptaron/h) keeps the upstream history of big projects in one bare
# repository per identity, the "store": nixpkgs, the kernel, GNOME and friends as remotes of a
# single repository under ~/.cache/git. Clones under the matching code root borrow objects from
# it, and reading upstream code never needs a checkout at all (`h store show`).
#
# The store is only useful when it is fresh, so these user units fetch every upstream hourly and
# run git's non-destructive maintenance tasks daily and weekly. `h store maintain` never runs
# `gc`, and the store's own configuration forbids pruning, because clones depend on its objects.
# `h store fetch` is best-effort: an upstream that cannot be fetched is named and the rest are
# still fetched, so a failed unit means "look at the journal", not "nothing was fetched".
#
# The stores themselves are created by `h store init` (or on the first `h store add`) from an
# interactive shell, where the identity options from the bashrc apply. Reading a store's refs
# needs git 2.45 or later; zebul's is well past that.
{
  config,
  lib,
  perSystem,
  ...
}:

let
  h = perSystem.h.default;

  # One store per identity, matching the `h` and `hq` functions in the bashrc. `$HOME` is
  # expanded by the script at run time; systemd specifiers like `%h` are not.
  stores = [
    "$HOME/.cache/git/philiptaron"
    "$HOME/.cache/git/PhilipTaronQ"
  ];

  # Run an `h store` subcommand against every store that exists, and fail if any of them failed.
  forEachStore =
    args:
    lib.concatMapStringsSep "\n" (store: ''
      if [ -d "${store}" ]; then
        ${h}/bin/h --store "${store}" store ${args} || status=1
      fi
    '') stores;

  # Fetching needs credentials for private upstreams, which come from the keyring over D-Bus,
  # but must never wait on a terminal.
  environment = {
    GIT_TERMINAL_PROMPT = "0";
  };

  # `h` runs the system git, the one with the libsecret credential helper.
  path = [ config.programs.git.package ];
in

{
  systemd.user.services.h-store-fetch = {
    description = "Fetch every upstream into the git object stores";
    inherit environment path;
    serviceConfig = {
      Type = "oneshot";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    script = ''
      status=0
      ${forEachStore "fetch --quiet"}
      ${forEachStore "maintain hourly"}
      exit $status
    '';
  };

  systemd.user.timers.h-store-fetch = {
    description = "Hourly fetch into the git object stores";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15min";
      OnUnitInactiveSec = "1h";
      RandomizedDelaySec = "10min";
    };
  };

  systemd.user.services."h-store-maintain@" = {
    description = "Run the %i maintenance tasks on the git object stores";
    inherit environment path;
    serviceConfig = {
      Type = "oneshot";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    scriptArgs = "%i";
    script = ''
      status=0
      ${forEachStore "maintain \"$1\""}
      exit $status
    '';
  };

  systemd.user.timers."h-store-maintain@daily" = {
    description = "Daily maintenance of the git object stores";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };

  systemd.user.timers."h-store-maintain@weekly" = {
    description = "Weekly maintenance of the git object stores";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };
}
