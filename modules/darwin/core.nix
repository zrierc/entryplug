{ config, lib, pkgs, inputs, vars, host, profile, homeModule, ... }:

{
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = 7;
  system.primaryUser = host.primaryUser;

  networking = {
    hostName = host.hostname;
    localHostName = host.hostname;
    computerName = host.computerName;
  };

  # The account already exists on macOS; declaring home only keeps nix-darwin
  # from trying to create it (creation requires an explicit uid).
  users.users.${host.primaryUser} = {
    home = host.home;
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];

      # Disk pressure safety net: when free space drops below min-free and Nix
      # needs to build or substitute, it runs GC until free space reaches
      # max-free, or nothing collectible is left.
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
    extraSpecialArgs = { inherit inputs vars host; };
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
