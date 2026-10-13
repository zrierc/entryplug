{ pkgs, ... }:

{
  programs.bat = {
    enable = true;

    # ansi follows whatever palette the terminal is themed with, so it applies 
    # in a pipe, over ssh and on a vm alike
    config = {
      theme = "ansi";
      style = "plain";
      paging = "never";
      color = "auto";
    };

    extraPackages = [ pkgs.bat-extras.batdiff ];
  };
}
