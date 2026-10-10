# Homebrew is a cask installer only. It is locked down in brew-lock.nix and by
# onActivation.cleanup, which refuses to activate if anything outside the
# generated Brewfile is installed.
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
      cleanup = "check";
      autoUpdate = false;
      upgrade = false;
    };

    # Only casks with no usable nixpkgs aarch64-darwin package live here.
    casks = [
      "obs"
      "steam"
      "orbstack"
      "vorssaint"
      "rustdesk"
      "anydesk"
      "tailscale-app"
      "helium-browser"
    ];
  };

  # global.autoUpdate = false sets HOMEBREW_NO_AUTO_UPDATE, which also freezes
  # the cask metadata cache. Let it refresh over HTTP (no git, so nix-homebrew's
  # synthetic repository is untouched) so `brew upgrade` sees current versions.
  environment.variables.HOMEBREW_FORCE_API_AUTO_UPDATE = "1";
}
