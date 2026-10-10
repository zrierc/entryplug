# Modern shell tooling for the agents profile. Only tools that need shell init
# or config get a home-manager module; the rest stay plain packages.
{ pkgs, lib, ... }:

let
  # eza's own aliases are mkDefault, so shell-common's plain ls/ll/la would win.
  # Force the eza versions for this profile only, key by key, so the other
  # shared aliases (cat, grep, l) still merge in.
  ezaAliases = {
    ls = lib.mkForce "eza --icons=auto";
    ll = lib.mkForce "eza -l --icons=auto";
    la = lib.mkForce "eza -a --icons=auto";
  };
in

{
  programs.zoxide.enable = true; # z/zi need the init hook
  programs.bat.enable = true; # config only; the cat alias lives in shell-common
  programs.eza.enable = true;

  programs.zsh.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin ezaAliases;
  programs.bash.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isLinux ezaAliases;
}
