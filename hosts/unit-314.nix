{
  hostname = "unit-314";
  computerName = "UNIT-314";
  platform = "aarch64-linux";
  primaryUser = "zrie";
  home = "/home/zrie";
  devRoot = "~/Dev";
  profiles = [ "agents" ];
  hardwareModules = [ ./unit-314-hardware.nix ];
}
