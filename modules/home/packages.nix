{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
    curl
    htop
    kubectl
    kubernetes-helm
    ripgrep
    tree
    wget
  ];
}
