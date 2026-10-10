# Ghostty itself is a cask and updates itself; only its config is managed here.
# Load order on macOS is $XDG_CONFIG_HOME/ghostty/config.ghostty, then
# .../config, then the ~/Library/Application Support/com.mitchellh.ghostty/*
# files, later ones winning — so an existing config in either place overrides
# this one.
{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.file.".config/ghostty/config.ghostty".text = ''
    font-family = Lilex Nerd Font Mono
    font-size = 13
  '';
}
