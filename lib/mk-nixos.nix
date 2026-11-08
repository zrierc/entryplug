{
  inputs,
  host,
  profile,
}:

inputs.nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit
      inputs
      host
      profile
      ;
    homeModule = ../profiles + "/${profile}/home.nix";
  };

  modules = [
    { nixpkgs.hostPlatform = host.platform; }
    # shortcut: the only linux host is a pi 4, move this to the host entry when a second board appears
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    inputs.home-manager.nixosModules.home-manager
    ../modules/nixos/core.nix
    (../profiles + "/${profile}/system.nix")
  ]
  ++ (host.hardwareModules or [ ]);
}
