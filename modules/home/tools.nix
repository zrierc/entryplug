{ pkgs, lib, ... }:

let
  # programs.eza emits ls/ll/la as mkDefault, the weakest priority, so the plain
  # definitions in shell-common.nix would win without this
  ezaAliases = {
    ls = lib.mkForce "eza";
    ll = lib.mkForce "eza -la";
    la = lib.mkForce "eza -a";
    l = lib.mkForce "eza --classify=auto";
  };

  agentsAliases = {
    vi = "command vim";
    vim = "nvim";
    lg = "lazygit";
  };
in

{
  programs.zoxide = {
    enable = true;
    options = [ "--cmd cd" ];
  };

  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
    extraOptions = [ "--group-directories-first" ];
  };

  programs.fd = {
    enable = true;

    # `.*` is a real ignore rule, so it hides dotfiles even from --hidden
    ignores = [ ".*" "node_modules" "venv" "!.config" "!.local" ];
  };

  programs.zsh.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (ezaAliases // agentsAliases);
  programs.bash.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (ezaAliases // agentsAliases);
}
