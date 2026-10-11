# the store copy is read-only, so Karabiner cannot save edits made in its own UI
{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.file.".config/karabiner/karabiner.json".source = ../../config/karabiner.json;
}
