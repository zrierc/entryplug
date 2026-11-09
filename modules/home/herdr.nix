# herdr comes from nixpkgs unstable. Its config keys are version-specific, so
# run `herdr config check` after a nixpkgs update.
{ pkgs, ... }:

{
  home.packages = [
    pkgs.herdr
  ];

  # The store copy is read-only, so `herdr config reset-keys` cannot rewrite it
  # and would have nothing to back up. Change config/herdr.toml and run
  # `herdr server reload-config` to apply it to a running server. herdr's own
  # sockets, logs, .plugins.lock and session.json live in the same directory
  # and stay its business, not home-manager's.
  home.file.".config/herdr/config.toml".source = ../../config/herdr.toml;
}
