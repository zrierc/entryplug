# macOS keeps the system /bin/zsh as login shell; home-manager only manages the
# rc files, so no shell registration or chsh is needed.
{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    history = {
      size = 1000;
      save = 2000;
      ignoreDups = true;
    };

    initContent = ''
      PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '
    '';
  };
}
