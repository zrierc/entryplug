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
    eza
    fd
    lazygit
    neovim
    ripgrep
    ripgrep-all
    tldr
    zoxide
  ];

  # neovim is the editor in this profile. vim stays installed and usable, it
  # just stops owning EDITOR/VISUAL (modules/home/vim.nix sets it as a default).
  programs.vim.defaultEditor = false;

  # No settings and no presets on purpose: home-manager then leaves
  # ~/.config/starship.toml alone (it only writes it when one of those is set),
  # so the prompt can be explored freely with `starship preset <name> -o`.
  # Declare it here once the config stops changing. See docs/operations.md.
  programs.starship.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
