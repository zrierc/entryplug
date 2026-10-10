{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
    curl
    htop
    kubectl
    ripgrep
    tree
    wget
  ];
}
