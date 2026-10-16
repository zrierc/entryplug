# AeroSpace is a cask (modules/darwin/homebrew.nix)
{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  # the store copy is read-only, so AeroSpace cannot save edits made in its own preferences
  home.file.".config/aerospace/aerospace.toml".source = ../../config/aerospace.toml;
}
