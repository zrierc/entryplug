{ pkgs, ... }:

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

    btop
    fd
    lazygit
    neovim
    ripgrep-all
    tldr
  ];

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

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
