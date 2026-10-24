# AeroSpace is a cask (modules/darwin/homebrew.nix); this only owns its config
# and the workspace helper.
{ pkgs, lib, ... }:

let
  # AeroSpace spawns key bindings with PATH=/usr/bin:/bin:/usr/sbin:/sbin, so the
  # binding below reaches this script through $HOME instead of PATH.
  aeroWorkspace = pkgs.writeShellApplication {
    name = "aero-workspace";
    runtimeInputs = [ pkgs.gnugrep ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "usage: aero-workspace <workspace>" >&2
        exit 1
      fi

      aero=/opt/homebrew/bin/aerospace

      # i3 gives an existing workspace its output and creates a brand-new one on
      # the focused output; AeroSpace creates every new workspace on main.
      if "$aero" list-workspaces --all | grep -Fqx "$1"; then
        exec "$aero" workspace --auto-back-and-forth "$1"
      fi
      exec "$aero" summon-workspace "$1"
    '';
  };
in

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  # the store copy is read-only, so AeroSpace cannot save edits made in its own
  # preferences; change config/aerospace.toml and switch
  home.file.".config/aerospace/aerospace.toml".source = ../../config/aerospace.toml;

  home.file.".local/bin/aero-workspace".source = "${aeroWorkspace}/bin/aero-workspace";

  # the cask's CLI sits in /opt/homebrew/bin, which the brew shim keeps off PATH
  home.packages = [
    aeroWorkspace
    (pkgs.writeShellScriptBin "aerospace" ''
      exec /opt/homebrew/bin/aerospace "$@"
    '')
  ];
}
