{ pkgs, ... }:

{
  imports = [
    ../agents/home.nix
    ../../modules/home/ghostty.nix
  ];

  # ani-cli wraps its own mpv, yt-dlp, ffmpeg and fzf on PATH, so it works
  # without the system mpv below. Needs a video player to be useful, hence
  # workstation rather than agents.
  home.packages = [ pkgs.bitwarden-cli pkgs.ani-cli ];
}
