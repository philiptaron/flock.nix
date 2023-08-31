{ ... }:

{
  systemd.nspawn = {
    "ubuntu-jammy" = {
      execConfig.Capability = "all";
      execConfig.ResolvConf = "copy-stub";
      execConfig.Timezone = "copy";
      networkConfig.Private = false;
    };
  };
}
