# nix-darwin installs these into /Library/Fonts/Nix Fonts on activation.
{ pkgs, ... }:

{
  fonts.packages = [
    (pkgs.callPackage ../../packages/lilex-nerd-font.nix { })
  ];
}
