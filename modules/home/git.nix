{ config, lib, pkgs, ... }:

let
  devRoot = "~/Dev";
  keyDir = "${config.home.homeDirectory}/.ssh/key";
  secretFile = ../../secrets/secret.yaml;
  identityFile = id: "~/.config/git/identities/${id}.inc";

  # one account, one key
  dirs = {
    works = { id = "work"; key = "github_primary"; };
    college = { id = "college"; key = "github_college"; };
    personal = { id = "personal"; key = "github_primary"; };
    projects = { id = "personal"; key = "github_primary"; };
    learn = { id = "personal"; key = "github_primary"; };
  };

  keyNames = lib.unique (map (entry: entry.key) (lib.attrValues dirs));

  # sshCommand is static config, the identity file is written by activation
  # because the store cannot hold decrypted values
  includeFor = dir: entry: [
    {
      condition = "gitdir:${devRoot}/${dir}/";
      contents.core.sshCommand = "ssh -i ${keyDir}/${entry.key} -o IdentitiesOnly=yes";
    }
    {
      condition = "gitdir:${devRoot}/${dir}/";
      path = identityFile entry.id;
    }
  ];
in
{
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      rerere.enabled = true;
    };
    ignores = [ ".direnv/" ];
    includes = lib.concatLists (lib.mapAttrsToList includeFor dirs);
  };

  home.activation.gitIdentities = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    identities="$HOME/.config/git/identities"
    ageKey="$HOME/.config/sops/age/keys.txt"

    install -d -m 0700 "$identities"

    # one decrypt call, so a broken key prints one error instead of one per field
    tree=$(SOPS_AGE_KEY_FILE="$ageKey" ${pkgs.sops}/bin/sops decrypt \
      --extract "[\"git\"]" --output-type json ${secretFile}) || tree=""

    if [ -z "$tree" ] || [ "$tree" = null ]; then
      echo "entryplug: git identities unavailable; fix secrets/secret.yaml or set user.name/user.email by hand" >&2
    else
      for id in work college personal; do
        name=$(printf '%s' "$tree" | ${pkgs.jq}/bin/jq -r --arg id "$id" '.[$id].name // empty') || name=""
        email=$(printf '%s' "$tree" | ${pkgs.jq}/bin/jq -r --arg id "$id" '.[$id].email // empty') || email=""
        if [ -z "$name" ] || [ -z "$email" ]; then
          echo "entryplug: git identity '$id' missing from secrets/secret.yaml" >&2
          continue
        fi
        tmp="$identities/$id.inc.tmp.$$"
        ${pkgs.git}/bin/git config --file "$tmp" user.name "$name"
        ${pkgs.git}/bin/git config --file "$tmp" user.email "$email"
        chmod 600 "$tmp"
        mv -f "$tmp" "$identities/$id.inc"
      done
    fi
  '';

  # warn at switch time, so a missing key does not surface as "Permission denied" on the first push
  home.activation.gitKeys = lib.hm.dag.entryAfter [ "gitIdentities" ] ''
    for name in ${lib.escapeShellArgs keyNames}; do
      [ -f "$HOME/.ssh/key/$name" ] \
        || echo "entryplug: missing ~/.ssh/key/$name; restore it from the secret manager" >&2
    done
  '';
}
