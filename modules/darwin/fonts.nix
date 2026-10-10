{ pkgs, ... }:

{
  fonts.packages = [
    (pkgs.callPackage ../../packages/lilex-nerd-font.nix { })
  ];
}
