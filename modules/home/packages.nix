{ pkgs, ... }:

{
  home.packages = with pkgs; [
    curl
    htop
    kubectl
    ripgrep
    rsync
    tree
    wget
  ];
}
