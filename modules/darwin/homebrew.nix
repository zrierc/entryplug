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

    # no usable nixpkgs package, or a driver and privileged daemons the store
    # copy cannot install (karabiner-elements)
    casks = [
      "karabiner-elements"
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
      "audacity"
      "nikitabobko/tap/aerospace"
      "microsoft-word"
      "microsoft-excel"
      "microsoft-powerpoint"
      "zotero"
    ];
  };

  # refresh cask metadata over HTTP; nix-homebrew's git repo is synthetic
  environment.variables.HOMEBREW_FORCE_API_AUTO_UPDATE = "1";
}
