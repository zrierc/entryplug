{
  description = "entry-plug: layer between pilot and machine. Load anywhere, anytime.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # unused: helium comes from the cask now
    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin.follows = "nixpkgs";
    };

    pi = {
      url = "github:earendil-works/pi/stable";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin-x64.follows = "nixpkgs";
    };

    herdr = {
      url = "github:herdrdev/herdr/v0.9.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      inherit (nixpkgs) lib;

      hosts = {
        unit-05 = import ./hosts/unit-05.nix;
      };

      # linux homeConfigurations are not tied to a host, so the user comes from the only declared host
      username = hosts.unit-05.primaryUser;

      darwinProfiles = [ "headless" "agents" "workstation" ];
      linuxProfiles = [ "headless" ];
      allSystems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];

      mkDarwin = hostName: profile:
        import ./lib/mk-host.nix {
          inherit inputs profile;
          host = hosts.${hostName};
        };

      mkHome = system: profile:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./modules/home/base.nix
            (./profiles + "/${profile}/home.nix")
            {
              home.username = username;
              home.homeDirectory = "/home/${username}";
            }
          ];
        };

      mkAppProgram = system: profile:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        import ./lib/apps.nix {
          inherit lib pkgs username profile self;
          darwinRebuild =
            if lib.hasSuffix "darwin" system
            then nix-darwin.packages.${system}.darwin-rebuild
            else null;
          homeManager = home-manager.packages.${system}.home-manager;
        };

      mkApp = system: profile:
        {
          type = "app";
          program = "${mkAppProgram system profile}/bin/${profile}";
          meta.description = "entryplug: switch this machine to the '${profile}' profile";
        };

      dottedDarwinConfigurations = lib.listToAttrs (lib.concatMap
        (hostName:
          let host = hosts.${hostName}; in
          map
            (profile: lib.nameValuePair "${host.hostname}.${profile}" (mkDarwin hostName profile))
            host.profiles)
        (lib.attrNames hosts));

      # darwin-rebuild cannot address attribute names containing a dot.
      darwinConfigurations = dottedDarwinConfigurations // lib.mapAttrs'
        (name: config: lib.nameValuePair (builtins.replaceStrings [ "." ] [ "-" ] name) config)
        dottedDarwinConfigurations;
    in
    {
      inherit darwinConfigurations;

      homeConfigurations = lib.listToAttrs (lib.concatMap
        (system:
          map
            (profile: lib.nameValuePair
              "${username}@linux-${lib.removeSuffix "-linux" system}-${profile}"
              (mkHome system profile))
            linuxProfiles)
        [ "x86_64-linux" "aarch64-linux" ]);

      apps = lib.genAttrs allSystems
        (system:
          let
            profiles = if lib.hasSuffix "darwin" system then darwinProfiles else linuxProfiles;
          in
          (lib.genAttrs profiles (profile: mkApp system profile))
          // { default = mkApp system "headless"; });

      # checks are per system; the darwin ones only build on the Mac
      checks = lib.genAttrs allSystems
        (system:
          let
            profiles = if lib.hasSuffix "darwin" system then darwinProfiles else linuxProfiles;
          in
          lib.genAttrs profiles (profile: mkAppProgram system profile));
    };
}
