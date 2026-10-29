# gh has no includeIf, so a wrapper picks the account from $PWD and exports
# GH_TOKEN for that one process. Auth itself stays with `gh auth login`, which
# stores and refreshes the token in the keychain.
{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;
  real = "${pkgs.gh}/bin/gh";
  git = "${pkgs.git}/bin/git";

  # shortcut: dir to identity mirrors git.nix; put both in one file if a dir is
  # ever added to only one of them
  dirs = {
    works = "work";
    college = "college";
    personal = "personal";
    projects = "personal";
    learn = "personal";
  };

  # trailing slash plus the /* glob mirrors git's gitdir: includes: subdirectories
  # and submodules match, ~/Dev/works-old does not
  caseArms = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (dir: id: ''      "${home}/Dev/${dir}"/*) id=${lib.escapeShellArg id} ;;'') dirs
  );
in
{
  # the wrapper replaces the package, so `gh` is the only gh on PATH
  home.packages = [
    (pkgs.writeShellScriptBin "gh" ''
      # auth commands must see gh's own config, not the directory's token
      if [ "''${1:-}" != auth ] && [ -z "''${GH_TOKEN:-}" ] && [ -z "''${GITHUB_TOKEN:-}" ]; then
        id=
        case "$PWD/" in
      ${caseArms}
        esac
        if [ -n "$id" ]; then
          # git.nix writes user.name from secret.yaml as git.<id>.name, and that
          # value is the GitHub login, so the username stays in sops
          user=$(${git} config --file "${home}/.config/git/identities/$id.inc" user.name 2>/dev/null) || user=
          if [ -n "$user" ] && token=$(${real} auth token --hostname github.com --user "$user" 2>/dev/null); then
            export GH_TOKEN=$token
          else
            echo "gh: no github.com login for $id; run 'cd ~ && gh auth login'" >&2
          fi
        fi
      fi
      exec ${real} "$@"
    '')
  ];

  # hosts.yml stays unmanaged: `gh auth login` owns it
  xdg.configFile."gh/config.yml".source = (pkgs.formats.yaml { }).generate "gh-config.yml" {
    version = "1";
    git_protocol = "ssh";
    prompt = "enabled";
  };
}
