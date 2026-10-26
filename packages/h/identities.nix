# The two identities I run `h` under, by the name of the command for each: `h` for personal work,
# `hq` for Qumulo. Each has its own code root, object store and git options. The git options are
# a string as `h-shell-init --git-opts` and `$H_GIT_OPTS` take it, split as a shell would.
#
# Both the wrapped binaries (./default.nix) and the shell functions (../dotfiles/bash/bashrc) are
# made from this, so they always clone with the same identity.
{
  h = {
    root = "~/Code";
    store = "~/.cache/git/philiptaron";
    gitOpts = ''-c user.name="Philip Taron" -c user.email="philip.taron@gmail.com" -c user.signingkey="~/.ssh/personal_id_ed25519.pub" -c credential.username="philiptaron"'';
  };
  hq = {
    root = "~/Qumulo";
    store = "~/.cache/git/PhilipTaronQ";
    gitOpts = ''-c user.name="Philip Taron" -c user.email="philip@qumulo.com" -c user.signingkey="~/.ssh/qumulo_id_ed25519.pub" -c credential.username="PhilipTaronQ"'';
  };
}
