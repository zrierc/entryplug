{ config, lib, pkgs, ... }:

let
  blocked = pkgs.writeShellApplication {
    name = "brew";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      real=${lib.escapeShellArg "${config.homebrew.prefix}/bin/brew"}
      if [ ! -x "$real" ]; then
        printf >&2 'entryplug: Homebrew is not installed by this configuration.\n'
        exit 1
      fi

      cmd="''${1:---help}"
      case "$cmd" in
        list|ls|info|search|desc|deps|uses|outdated|doctor|config|home|help|tap-info|leaves|cat|log|--prefix|--version|--cellar|--repository)
          exec "$real" "$@"
          ;;
        upgrade)
          # skips auto_updates casks unless --greedy; those update themselves
          exec "$real" "$@"
          ;;
        uninstall)
          # drift escape hatch; declared casks return next activation
          exec "$real" "$@"
          ;;
        *)
          printf >&2 "entryplug: refusing 'brew %s'\n" "$cmd"
          printf >&2 '%s\n' \
            'Homebrew here only installs the casks declared in profiles/workstation.' \
            'Add the package to that profile, or use nixpkgs, then run:' \
            '  nix run .#workstation'
          exit 1
          ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ (lib.hiPrio blocked) ];
}
