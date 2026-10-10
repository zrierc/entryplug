{ pkgs, ... }:

{
  imports = [
    ../agents/home.nix
    ../../modules/home/ghostty.nix
  ];

  # ani-cli wraps its own mpv, yt-dlp, ffmpeg and fzf on PATH, so it does not
  # need the system mpv from system.nix. It sits here, not in agents, because it
  # is only useful with a video player around.
  home.packages = [ pkgs.bitwarden-cli pkgs.ani-cli ];
}
