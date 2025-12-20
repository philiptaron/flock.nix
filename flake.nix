{
  description = "Philip Taron's flock of Nix configuration(s)";
  nixConfig.commit-lockfile-summary = "flake.nix: update the lockfile";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  inputs.systems.url = "github:nix-systems/default";

  inputs.blueprint.url = "github:numtide/blueprint";
  inputs.blueprint.inputs.nixpkgs.follows = "nixpkgs";
  inputs.blueprint.inputs.systems.follows = "systems";

  inputs.llm-agents.url = "github:numtide/llm-agents.nix";
  inputs.llm-agents.inputs.nixpkgs.follows = "nixpkgs";
  inputs.llm-agents.inputs.blueprint.follows = "blueprint";

  # Load the blueprint
  outputs = inputs: inputs.blueprint { inherit inputs; };
}
