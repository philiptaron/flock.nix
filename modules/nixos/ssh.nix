# SSH client configuration.
#
# This module:
# - Disables SSH_ASKPASS so missing credentials fail instead of prompting
# - Forwards COLORTERM to enable truecolor on remote hosts
{
  # Disable SSH_ASKPASS so that missing credentials fail with an error instead
  # of popping up an ugly X11 dialog. Credentials should be in the ssh-agent
  # or GNOME Keyring; if they're not, fail fast so we know to fix the config.
  programs.ssh.enableAskPassword = false;

  # Forward COLORTERM to remote hosts so they know the terminal supports
  # truecolor (24-bit). The remote sshd must have AcceptEnv COLORTERM.
  programs.ssh.extraConfig = ''
    Host *
        SendEnv COLORTERM
  '';
}
