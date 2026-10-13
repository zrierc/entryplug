# ~/Library/Application Support config loads after this file
{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.file.".config/ghostty/config.ghostty".text = ''
    # built-in theme
    theme = light:Flexoki Light,dark:Poimandres Darker

    font-family = Lilex Nerd Font Mono
    font-thicken = true
    font-size = 14

    # ligatures live in calt
    # Uncomment what you want:
    #
    # font-feature = -calt   # programming ligatures off
    # font-feature = +zero   # slashed zero
    # font-feature = +ss01   # stylistic sets, Lilex has ss01-ss05
    # font-feature = +cv01   # character variants, Lilex has cv01-cv15
  '';
}
