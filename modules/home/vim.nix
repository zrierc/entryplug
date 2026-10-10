{ lib, ... }:

{
  programs.vim = {
    enable = true;
    # Overridable: the agents profile points EDITOR at nvim instead.
    defaultEditor = lib.mkDefault true;
    extraConfig = lib.fileContents ../../config/.vimrc;
  };
}
