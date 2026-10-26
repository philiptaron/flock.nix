# The identities I run `h` under on zebul: `h` for personal work, `hq` for Qumulo. See
# modules/nixos/h.nix for what each one gets.
{
  programs.h.identities = {
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
  };
}
