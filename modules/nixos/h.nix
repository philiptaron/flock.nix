# `h` (https://github.com/philiptaron/h) under each of my identities.
#
# An identity is a code root, an object store and the git options every clone gets: who I commit
# as, what I sign with, which credentials I fetch with. The host names them in
# `programs.h.identities`, by the name of the command for each, and this module makes the rest
# agree with them:
#
# - a shell function of that name, from `h-shell-init`, which jumps to projects with `pushd` and
#   clones what is missing;
# - a wrapped binary of that name, for scripts, hooks and agents, which run the binary rather
#   than the function (see packages/h);
# - the identity's store, kept fresh.
#
# The store keeps the upstream history of big projects in one bare repository per identity:
# nixpkgs, the kernel, GNOME and friends as remotes of a single repository under ~/.cache/git.
# Clones under the matching code root borrow objects from it, and reading upstream code never
# needs a checkout at all (`h store show`).
#
# The store is only useful when it is fresh, so these user units fetch every upstream hourly and
# run git's non-destructive maintenance tasks daily and weekly. `h store maintain` never runs
# `gc`, and the store's own configuration forbids pruning, because clones depend on its objects.
# `h store fetch` is best-effort: an upstream that cannot be fetched is named and the rest are
# still fetched, so a failed unit means "look at the journal", not "nothing was fetched".
#
# The stores themselves are created by `h store init` (or on the first `h store add`) from an
# interactive shell, where the identity's git options apply; later fetches use the credentials
# the store was made with. Reading a store's refs needs git 2.45 or later; zebul's is well past
# that.
{
  config,
  lib,
  perSystem,
  ...
}:

let
  inherit (lib) mkOption types;
  cfg = config.programs.h;
  h = perSystem.h.default;

  # One store per identity. `$HOME` is expanded by the script at run time, where a `~` in quotes
  # would not be; systemd specifiers like `%h` are not expanded there either.
  stores = lib.mapAttrsToList (
    _: identity: lib.replaceStrings [ "~/" ] [ "$HOME/" ] identity.store
  ) cfg.identities;

  # Run an `h store` subcommand against every store that exists, and fail if any of them failed.
  forEachStore =
    args:
    lib.concatMapStringsSep "\n" (store: ''
      if [ -d "${store}" ]; then
        ${h}/bin/h --store "${store}" store ${args} || status=1
      fi
    '') stores;

  # The shell function for an identity, named after it.
  shellFunction =
    name: identity:
    let
      arg = lib.escapeShellArg;
    in
    ''
      eval "$(${h}/bin/h-shell-init --pushd --name ${name} --store ${arg identity.store} --git-opts ${arg identity.gitOpts} ${arg identity.root})"
    '';

  # Fetching needs credentials for private upstreams, which come from the keyring over D-Bus,
  # but must never wait on a terminal.
  environment = {
    GIT_TERMINAL_PROMPT = "0";
  };

  # `h` runs the system git, the one with the libsecret credential helper. Upstreams with `ssh://`
  # URLs need `ssh` too; it finds the agent through the SSH_AUTH_SOCK the user manager exports.
  path = [
    config.programs.git.package
    config.programs.ssh.package
  ];
in

{
  options.programs.h.identities = mkOption {
    description = ''
      The identities to run `h` under, by the name of the command for each. Each gets a shell
      function and a wrapped binary of that name, and its store is kept fresh.
    '';
    example = lib.literalExpression ''
      {
        h = {
          root = "~/Code";
          store = "~/.cache/git/me";
          gitOpts = '''-c user.name="Me" -c credential.username="me"''';
        };
      }
    '';
    type = types.attrsOf (
      types.submodule {
        options = {
          root = mkOption {
            type = types.str;
            description = "The code root projects are cloned under. A leading `~/` is the home directory.";
          };
          store = mkOption {
            type = types.str;
            description = "The object store clones borrow from. A leading `~/` is the home directory.";
          };
          gitOpts = mkOption {
            type = types.str;
            default = "";
            description = ''
              The git options (`-c key=value`) written into every clone and into the store, as one
              string, the way `h-shell-init --git-opts` and `$H_GIT_OPTS` take them.
            '';
          };
        };
      }
    );
  };

  config = {
    environment.systemPackages = [
      (perSystem.self.h.override { inherit (cfg) identities; })
    ];

    programs.bash.interactiveShellInit = lib.concatStrings (
      lib.mapAttrsToList shellFunction cfg.identities
    );

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
  };
}
