{ config, pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    history = {
      size = 1000;
      save = 2000;
      ignoreDups = true;
    };

    # skipped when starship manages the prompt
    initContent = lib.mkIf (!config.programs.starship.enable) ''
      PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '
    '';
  };
}
