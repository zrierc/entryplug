{ lib, ... }:

{
  programs.vim = {
    enable = true;
    defaultEditor = true;
    extraConfig = lib.fileContents ../../config/.vimrc;
  };
}
