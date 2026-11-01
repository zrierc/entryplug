# Vesktop's arRPC has no process scanner on darwin, so it never
# notices a Steam game causes Discord rich presence not working.
{ pkgs, config, ... }:

let
  steamPresence = pkgs.writeTextFile {
    name = "steam-presence";
    destination = "/bin/steam-presence";
    executable = true;
    text = ''
      #!${pkgs.python3.interpreter}
      ${builtins.readFile ./scripts/steam-presence.py}
    '';
  };
in

{
  home.packages = [ steamPresence ];

  launchd.agents.steam-presence = {
    enable = true;
    restartTriggers = [ steamPresence ];
    config = {
      ProgramArguments = [ "${steamPresence}/bin/steam-presence" ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/steam-presence.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/steam-presence.log";
    };
  };
}
