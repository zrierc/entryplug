{ pkgs, ... }:

{
  imports = [
    ../agents/home.nix
    ../../modules/home/ghostty.nix
    ../../modules/home/karabiner.nix
    ../../modules/home/aerospace.nix
  ];

  # needs a video player, so workstation not agents
  home.packages = [ pkgs.ani-cli ];
}
