# macOS-only profile: GUI apps come from environment.systemPackages (nix-darwin
# copies them into /Applications/Nix Apps) plus the casks in modules/darwin/homebrew.nix.
{ pkgs, lib, ... }:

{
  imports = [
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/brew-lock.nix
    ../../modules/darwin/fonts.nix
  ];

  environment.systemPackages = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (with pkgs; [
    bitwarden-desktop
    firefox-bin
    ghostty-bin
    mpv
  ]);
}
