# Profile entry point. Detects the current host and switches it into the
# requested profile, using the same flake revision this app was invoked from.
{ lib
, pkgs
, self
, vars
, profile
, darwinRebuild
, homeManager
}:

let
  flake = toString self;

  darwinBranch = lib.optionalString (darwinRebuild != null) ''
    if [ "$(uname -s)" = "Darwin" ]; then
      attr="$host-$profile"
      has_attr "$attr" || fail "no darwinConfiguration '$attr' for host '$host'; set ENTRYPLUG_HOST if this Mac's name differs"
      exec sudo ${darwinRebuild}/bin/darwin-rebuild switch --flake "$flake#$attr" "$@"
    fi
  '';
in

pkgs.writeShellApplication {
  name = profile;
  runtimeInputs = [ pkgs.coreutils ];
  text = ''
    flake=${lib.escapeShellArg flake}
    profile=${lib.escapeShellArg profile}
    user=${lib.escapeShellArg vars.username}

    fail() { printf >&2 'entry-plug: %s\n' "$*"; exit 1; }

    has_attr() {
      nix eval --raw "$flake#$1" --apply 'x: "ok"' >/dev/null 2>&1
    }

    host=""
    case "$(uname -s)" in
      Darwin)
        host="$(scutil --get LocalHostName 2>/dev/null || scutil --get ComputerName 2>/dev/null || true)"
        ;;
      Linux)
        host="$(cat /proc/sys/kernel/hostname 2>/dev/null || true)"
        ;;
      *)
        fail "unsupported platform: $(uname -s)"
        ;;
    esac

    host="''${ENTRYPLUG_HOST:-$host}"
    host="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]' | cut -d. -f1)"
    [ -n "$host" ] || fail "cannot detect the hostname; set ENTRYPLUG_HOST"
    case "$host" in
      *[!a-z0-9-]*) fail "invalid hostname '$host' (allowed: a-z, 0-9, -)" ;;
    esac

    ${darwinBranch}

    if [ -e /etc/NIXOS ]; then
      attr="$host.$profile"
      has_attr "nixosConfigurations.\"$attr\"" || fail "no nixosConfiguration '$attr' for host '$host'"
      exec sudo nixos-rebuild switch --flake "$flake#$attr" "$@"
    fi

    attr="$user@linux-$(uname -m)-$profile"
    has_attr "homeConfigurations.\"$attr\"" || fail "no homeConfiguration '$attr'; this profile may be macOS-only"
    exec ${homeManager}/bin/home-manager switch -b hm-backup --flake "$flake#$attr" "$@"
  '';
}
