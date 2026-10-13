{ pkgs, lib, ... }:

let
  # programs.eza emits ls/ll/la as mkDefault, the weakest priority, so the plain
  # definitions in shell-common.nix would win without this. The forced aliases
  # call `eza` itself: the flags live once, on the alias the module generates.
  ezaAliases = {
    ls = lib.mkForce "eza";
    ll = lib.mkForce "eza -la";
    la = lib.mkForce "eza -a";
    l = lib.mkForce "eza --classify=auto";
  };
  # `command` keeps vi off the chain below
  editorAliases = {
    vi = "command vim";
    vim = "nvim";
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

  programs.zsh.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (ezaAliases // editorAliases);
  programs.bash.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (ezaAliases // editorAliases);
}
