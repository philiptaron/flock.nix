{
  # `awscli2` is the command line interface for Amazon Web Services.
  # https://aws.amazon.com/cli/
  awscli2,

  # `azure-cli` is the command line interface for Microsoft Azure.
  # https://learn.microsoft.com/en-us/cli/azure/
  azure-cli,

  # `codex` is a terminal agent for the GPT series of models from OpenAI.
  # https://openai.com/codex
  codex,

  # `ghostty` is a terminal emulator from Mitchell Hashimoto.
  # https://ghostty.org/
  ghostty,

  # `chromium` is a browser from Google.
  # https://www.chromium.org/
  chromium,

  # `discord` is an all-in-one cross-platform voice and text chat for ~gamers~
  # https://discordapp.com/
  discord,

  # `gh` is the command line GitHub client.
  # https://cli.github.com/
  gh,

  # `google-cloud-sdk` is the command line interface for Google Cloud Platform.
  # https://cloud.google.com/sdk/
  google-cloud-sdk,

  # `oci-cli` is the command line interface for Oracle Cloud Infrastructure.
  # https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm
  oci-cli,

  # `signal` is the Signal secure messaging client.
  # https://signal.org/
  signal-desktop,

  # Slack is the Searchable Log of All Conversation and Knowledge.
  # https://slack.com/
  slack,

  # `terraform` is an infrastructure as code tool by HashiCorp.
  # https://www.terraform.io/
  terraform,

  # Zoom is a cloud-based video communications platform that enables virtual meetings, webinars,
  # messaging, and collaboration across devices.
  # https://zoom.us/
  zoom-us,

  # These are my customized packages (listed below)
  philiptaron,
}@args:

let
  pkgs = removeAttrs args [ "philiptaron" ] // {
    inherit (philiptaron)
      # `alacritty` is a cross-platform, GPU-accelerated terminal emulator.
      # https://github.com/alacritty/alacritty
      alacritty

      # `claude` is a terminal agent for the Opus and Sonnet series of models from Anthropic.
      # https://www.claude.com/product/claude-code
      claude-code

      # `gemini` is a terminal agent for the Gemini series of models from Google.
      # https://github.com/google-gemini/gemini-cli
      gemini-cli
      ;
  };
in
builtins.attrValues pkgs
