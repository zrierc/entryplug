{ config, ... }:
{
  programs.direnv = {
    enable = true;
    # every .envrc under ~/Dev runs without prompting; only your own clones belong there
    config.whitelist.prefix = [ "${config.home.homeDirectory}/Dev" ];
  };
}
