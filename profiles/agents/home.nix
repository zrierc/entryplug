{ config, pkgs, ... }:

{
  imports = [
    ../headless/home.nix
    ../../modules/home/tools.nix
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

  # config/starship.toml is the source of truth, and home-manager takes over
  # ~/.config/starship.toml on activation, moving any loose file aside as
  # starship.toml.hm-backup. The repo file is a full default dump with the
  # top-level globals stripped, so the prompt keeps starship's built-in format
  # and each module table only styles its own segment. See docs/operations.md.
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../../config/starship.toml);
  };
}
