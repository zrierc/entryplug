{ pkgs, ... }:

{
  imports = [
    ../agents/home.nix
    ../../modules/home/ghostty.nix
  ];

  home.packages = [ pkgs.bitwarden-cli ];
}
