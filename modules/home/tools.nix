{ pkgs, lib, ... }:

let
  ezaAliases = {
    ls = lib.mkForce "eza --icons=auto";
    ll = lib.mkForce "eza -l --icons=auto";
    la = lib.mkForce "eza -a --icons=auto";
  };
in

{
  programs.zoxide.enable = true; # z/zi need the init hook
  programs.eza.enable = true;

  programs.zsh.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin ezaAliases;
  programs.bash.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isLinux ezaAliases;
}
