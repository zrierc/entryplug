{ config, pkgs, ... }:

{
  imports = [
    ../headless/home.nix
    ../../modules/home/tools.nix
    ../../modules/home/scripts/hrdr.nix
    ../../modules/home/pi
    ../../modules/home/herdr.nix
    ../../modules/home/nvim.nix
  ];

  home.packages = with pkgs; [
    bun
    nodejs_26

    awscli2
    bitwarden-cli
    btop
    lazygit
    neovim
    ripgrep-all
    terraform
    tldr
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    GOPATH = "${config.home.homeDirectory}/Dev/go";
    GOBIN = "${config.home.homeDirectory}/Dev/go/bin";
  };

  home.sessionPath = [ "$HOME/Dev/go/bin" ];

  programs.vim.defaultEditor = false;

  # load from dedicated config file because it'll be too long
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../../config/starship.toml);
  };
}
