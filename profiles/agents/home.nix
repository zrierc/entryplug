{ pkgs, ... }:

{
  imports = [
    ../headless/home.nix
    ../../modules/home/pi
    ../../modules/home/herdr.nix
  ];

  # Node 26 for day-to-day npm work. pi bundles its own Node 22 runtime, so a
  # skill with native deps compiled here may not load inside pi.
  home.packages = [ pkgs.nodejs_26 pkgs.bun ];
}
