{ lib, ... }:

{
  programs.vim = {
    enable = true;
    # mkDefault so a profile can take EDITOR over
    defaultEditor = lib.mkDefault true;
    extraConfig = lib.fileContents ../../config/.vimrc;
  };
}
