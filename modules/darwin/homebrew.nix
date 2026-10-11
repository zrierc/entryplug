{ config, lib, pkgs, ... }:

{
  nix-homebrew = {
    enable = true;
    user = config.system.primaryUser;
    enableRosetta = false;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;

    global = {
      autoUpdate = false;
      brewfile = true;
    };

    onActivation = {
      cleanup = "uninstall";
      autoUpdate = false;
      upgrade = false;
    };

    # only casks with no usable nixpkgs aarch64-darwin package
    casks = [
      "obs"
      "steam"
      "orbstack"
      "vorssaint"
      "rustdesk"
      "anydesk"
      "tailscale-app"
      "helium-browser"
      "vesktop"
      "vlc"
    ];
  };

  # refresh cask metadata over HTTP; nix-homebrew's git repo is synthetic
  environment.variables.HOMEBREW_FORCE_API_AUTO_UPDATE = "1";
}
