# herdr is a pinned flake input, pinned because the config keys below are
# version-specific: v0.9.3 is what this repo declares.
{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # The store copy is read-only, so `herdr config reset-keys` cannot rewrite it
  # and would have nothing to back up. Change config/herdr.toml and run
  # `herdr server reload-config` to apply it to a running server. herdr's own
  # sockets, logs, .plugins.lock and session.json live in the same directory
  # and stay its business, not home-manager's.
  home.file.".config/herdr/config.toml".source = ../../config/herdr.toml;
}
