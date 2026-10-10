{ pkgs, ... }:

{
  imports = [ ../agents/home.nix ];

  home.packages = [ pkgs.bitwarden-cli ];
}
