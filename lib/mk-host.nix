{ inputs, vars, host, profile }:

inputs.nix-darwin.lib.darwinSystem {
  specialArgs = {
    inherit inputs vars host profile;
    homeModule = ../profiles + "/${profile}/home.nix";
  };

  modules = [
    { nixpkgs.hostPlatform = host.platform; }
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.home-manager.darwinModules.home-manager
    ../modules/darwin/core.nix
    (../profiles + "/${profile}/system.nix")
  ];
}
