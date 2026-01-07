# Opinionated git defaults without personal identity.
#
# Many of these settings come from this blog post:
#   <https://blog.gitbutler.com/how-git-core-devs-configure-git/>
#
# This module:
# - Enables git and git-lfs
# - Places config in /etc/gitconfig (system-wide)
# - Uses libsecret (GNOME Keyring) for credential storage
# - Requires commit signing (will error without per-repo user.signingkey)
# - Does NOT configure user identity (name/email/signing key)
# - Disables SSH_ASKPASS so missing credentials fail instead of prompting
#
# Each repo must be configured with identity before committing.
{ pkgs, ... }:

{
  # `git` is a distributed version control system.
  # https://git-scm.com/
  programs.git.enable = true;

  programs.git.package = pkgs.git.override {
    withLibsecret = true;
  };

  # `git-lfs` is used to distribute large files with Git.
  # https://git-lfs.github.com/
  programs.git.lfs.enable = true;

  # Disable SSH_ASKPASS so that missing credentials fail with an error instead
  # of popping up an ugly X11 dialog. Credentials should be in the ssh-agent
  # or GNOME Keyring; if they're not, fail fast so we know to fix the config.
  programs.ssh.enableAskPassword = false;

  # System-wide git configuration.
  environment.etc."gitconfig".text = ''
    [init]
            defaultBranch = main    # name the default branch `main` (short!)

    [core]
            commentChar = ";"       # I like being able to use markdown in commit messages

    [column]
            ui = auto               # show in columns if the output is to the terminal

    [branch]
            sort = -committerdate   # sorts the list by the most recent commit date, top is new

    [tag]
            sort = version:refname  # treats dotted version numbers as a series of integer values

    [diff]
            algorithm = histogram   # makes the diff more sane to humans
            colorMoved = plain      # make moved lines stand out differently to changed lines
            mnemonicPrefix = true   # replace `a` and `b` with `i` index, `w` working, or `c` commit
            renames = true          # detect if a file has been moved

    [merge]
            conflictstyle = zdiff3  # better merge default

    [push]
            default = simple        # push the current branch with the same name on the remote
            autoSetupRemote = true  # set the upstream up automatically

    [fetch]
            prune = true            # remove refs locally that were removed in the remote
            all = true              # just get everything every time

    [pull]
            rebase = true           # always rebase on pull

    [help]
            autocorrect = prompt    # if git knows what I meant, prompt for that

    [credential]
            helper = libsecret      # store credentials in GNOME Keyring

    [credential "https://github.com"]
            username = nobody       # force per-repo credential.username

    [gpg]
            format = ssh            # use SSH keys for signing

    [commit]
            verbose = true          # show the commit in diff form when editing the message
            gpgsign = true          # require signing (will error without user.signingkey)

    [rerere]
            enabled = true          # reuse recorded resolutions
            autoupdate = true       # keep them up to date

    [rebase]
            autoSquash = true       # for fixups
            autoStash = true        # for running on a dirty working tree
            updateRefs = true       # keep branches up to date

    [alias]
            # From https://stackoverflow.com/a/63145145 -- a wonderful "history" preset.
            hs = log --pretty='%C(yellow)%h %C(cyan)%cd %Cblue%aN%C(auto)%d %Creset%s' --graph --date=relative --date-order
  '';
}
