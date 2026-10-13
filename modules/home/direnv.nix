# direnv loads a project's environment on entry; nix-direnv adds the caching and the
# reload-on-flake-change that plain `use flake` lacks
{ config, ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.whitelist.prefix = [
      "${config.home.homeDirectory}/Dev"
      "${config.home.homeDirectory}/Works"
    ];
  };
}
