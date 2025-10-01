{ nix-eval-jobs, philiptaron }:

nix-eval-jobs.override {
  nixComponents = philiptaron.nix.libs;
}
