{ lib
, pkgs
, self
, username
, profile
, darwinRebuild
, homeManager
}:

let
  flake = toString self;

  darwinBranch = lib.optionalString (darwinRebuild != null) ''
    if [ "$(uname -s)" = "Darwin" ]; then
      attr="$host-$profile"
      has_attr darwinConfigurations "$attr" \
        || fail "no darwinConfiguration '$attr' for host '$host'. Available: $names. Set ENTRYPLUG_HOST if this Mac's name differs"
      if [ -n "$dryRun" ]; then
        note "--dry-run: building the system configuration only, nothing is activated"
        exec ${darwinRebuild}/bin/darwin-rebuild build --flake "$flake#$attr" "''${args[@]}"
      fi
      exec sudo ${darwinRebuild}/bin/darwin-rebuild switch --flake "$flake#$attr" "''${args[@]}"
    fi
  '';
in

pkgs.writeShellApplication {
  name = profile;
  runtimeInputs = [ pkgs.coreutils ];
  text = ''
    flake=${lib.escapeShellArg flake}
    profile=${lib.escapeShellArg profile}
    user=${lib.escapeShellArg username}

    fail() { printf >&2 'entryplug: %s\n' "$*"; exit 1; }
    note() { printf >&2 'entryplug: %s\n' "$*"; }

    # darwin-rebuild --dry-run is broken (it still runs `nix-env --set` on an
    # unbuilt path), so turn a dry run into a real build-only action instead.
    args=()
    dryRun=""
    for arg in "$@"; do
      case "$arg" in
        --dry-run|-n) dryRun=1 ;;
        *) args+=("$arg") ;;
      esac
    done

    # $1: flake output set (darwinConfigurations, nixosConfigurations,
    # homeConfigurations), $2: attribute name inside it. Sets `names` so the
    # caller can report what does exist.
    has_attr() {
      names=$(nix eval --json "$flake#$1" --apply 'x: builtins.attrNames x' 2>/dev/null || true)
      [[ $names == *'"'$2'"'* ]]
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
      has_attr nixosConfigurations "$attr" \
        || fail "no nixosConfiguration '$attr' for host '$host'. Available: $names"
      if [ -n "$dryRun" ]; then
        note "--dry-run: building the system configuration only, nothing is activated"
        exec sudo nixos-rebuild build --flake "$flake#$attr" "''${args[@]}"
      fi
      exec sudo nixos-rebuild switch --flake "$flake#$attr" "''${args[@]}"
    fi

    attr="$user@linux-$(uname -m)-$profile"
    has_attr homeConfigurations "$attr" \
      || fail "no homeConfiguration '$attr'. Available: $names"
    if [ -n "$dryRun" ]; then
      note "--dry-run: building the home configuration only, nothing is activated"
      exec ${homeManager}/bin/home-manager build --flake "$flake#$attr" "''${args[@]}"
    fi
    exec ${homeManager}/bin/home-manager switch -b hm-backup --flake "$flake#$attr" "''${args[@]}"
  '';
}
