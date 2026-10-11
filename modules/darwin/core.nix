{ config, lib, pkgs, inputs, host, profile, homeModule, ... }:

{
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = 7;
  system.primaryUser = host.primaryUser;

  networking = {
    hostName = host.hostname;
    localHostName = host.hostname;
    computerName = host.computerName;
  };

  # no uid: the account exists, nix-darwin would create it otherwise
  users.users.${host.primaryUser} = {
    home = host.home;
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];

      min-free = "40G";
      max-free = "100G";
    };

    gc = {
      automatic = true;
      interval = [ { Weekday = 7; Hour = 3; Minute = 15; } ];
      options = "--delete-older-than 15d";
    };

    optimise = {
      automatic = true;
      interval = [ { Weekday = 7; Hour = 4; Minute = 45; } ];
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs host; };
    users.${host.primaryUser} = {
      imports = [
        ../home/base.nix
        (import homeModule)
      ];
      home.username = host.primaryUser;
      home.homeDirectory = host.home;
    };
  };
}
