{ pkgs, ... }:

{
  imports = [
    ../agents/home.nix
    ../../modules/home/ghostty.nix
  ];

  # needs a video player, so workstation not agents
  home.packages = [ pkgs.ani-cli ];
}
