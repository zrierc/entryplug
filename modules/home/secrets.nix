{ pkgs, lib, config, ... }:

{
  home.packages = with pkgs; [
    sops
    age
  ];

  home.sessionVariables.SOPS_AGE_KEY_FILE =
    "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  home.activation.ensureAgeKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ageKey="$HOME/.config/sops/age/keys.txt"
    if [[ ! -f "$ageKey" ]]; then
      mkdir -p "$(dirname "$ageKey")"
      chmod 700 "$(dirname "$ageKey")"
      ${pkgs.age}/bin/age-keygen -o "$ageKey"
      chmod 600 "$ageKey"
    fi
  '';
}
