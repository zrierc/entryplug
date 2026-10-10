# macOS keeps the system /bin/zsh as login shell; home-manager only manages the
# rc files, so no shell registration or chsh is needed.
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

    # Only when starship is off: its init hook sets the prompt on every precmd,
    # so this would be dead code in the agents profile.
    initContent = lib.mkIf (!config.programs.starship.enable) ''
      PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '
    '';
  };
}
