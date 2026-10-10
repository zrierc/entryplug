# Homebrew is a cask installer only: brew-lock.nix restricts the command, and
# onActivation.cleanup removes anything not in the generated Brewfile, so the
# declared list is the only source of truth.
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

    # Only casks with no usable nixpkgs aarch64-darwin package live here.
    # GUI apps also come here when the nix store copy breaks Gatekeeper or
    # blocks the app's own updater: helium, vesktop.
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

  # global.autoUpdate = false sets HOMEBREW_NO_AUTO_UPDATE, which also freezes
  # the cask metadata cache. Let it refresh over HTTP (no git, so nix-homebrew's
  # synthetic repository is untouched) so `brew upgrade` sees current versions.
  environment.variables.HOMEBREW_FORCE_API_AUTO_UPDATE = "1";
}
