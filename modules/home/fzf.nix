{ pkgs, ... }:

{
  programs.fzf = {
    enable = true;
    enableBashIntegration = pkgs.stdenv.hostPlatform.isLinux;
    enableZshIntegration = pkgs.stdenv.hostPlatform.isDarwin;
  };
}
