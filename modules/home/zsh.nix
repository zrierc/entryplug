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
    initContent = lib.mkMerge [
      (lib.mkIf (!config.programs.starship.enable) ''
        PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '
      '')

      # nixpkgs gives terraform a bash completion only, and bashcompinit has to
      # come after compinit, which home-manager runs at order 570
      ''
        if command -v terraform >/dev/null; then
          autoload -U +X bashcompinit && bashcompinit
          complete -o nospace -C terraform terraform
        fi
      ''
    ];
  };
}
