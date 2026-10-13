{ ... }:

{
  home.stateVersion = "26.05";
  home.sessionPath = [ "$HOME/.local/bin" ];
  home.overwriteBackup = true;

  programs.home-manager.enable = true;
}
