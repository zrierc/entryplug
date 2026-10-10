# Modern shell tooling for the agents profile. Only tools that need shell init
# or config get a home-manager module; the rest are plain packages in the
# profile (fd, ripgrep-all, btop, lazygit, tldr, neovim, ani_cli).
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
  programs.zoxide.enable = true; # z / zi, needs the init hook to work at all
  programs.bat.enable = true; # theme and config; the `cat` alias is shared
  programs.eza.enable = true;

  programs.zsh.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin ezaAliases;
  programs.bash.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isLinux ezaAliases;
}
