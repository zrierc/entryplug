# Operations

## Homebrew policy

Homebrew exists here for one reason: a few GUI apps have no usable nixpkgs
`aarch64-darwin` package. Everything else comes from nixpkgs or a pinned flake.
Brew is treated as a cask installer that belongs to the configuration, not as a
package manager you use by hand.

Casks live in `modules/darwin/homebrew.nix`. Current list: obs, steam, orbstack,
vorssaint, rustdesk, anydesk, tailscale-app, helium-browser, vesktop, vlc.

Two GUI apps moved from nixpkgs to a cask even though nixpkgs packages them:
`helium-browser` (the flake's package disables the browser's self-update) and
`discord` (the nix store copy is refused by Gatekeeper as damaged, and the
nixpkgs package sets `disableUpdates`, so the app's own updater is off). Discord
has since been replaced by `vesktop`: nixpkgs builds Vesktop from source on
darwin, which lands read-only in `/Applications/Nix Apps` with the same
Gatekeeper class of problem, while the cask is prebuilt, notarized and
self-updating. Rule of
thumb: a GUI app that self-updates belongs in a cask.

Heads up on the helium name: the Homebrew cask `helium` is a different app
(koush's desktop installer). The one in this config is `helium-browser`. It has
`auto_updates: true`, so it updates itself, and it was moved off the `helium`
flake input for that reason — the flake's package explicitly disables the
browser's self-update. The flake input is still declared in `flake.nix`,
currently unused, in case a pinned browser is wanted again.

### Lock layers

1. **Fail-closed drift check** — `homebrew.onActivation.cleanup = "check"`.
   During `darwin-rebuild switch`, a `brew bundle cleanup` check runs before
   anything is applied. If any tap, formula or cask exists that is not in the
   generated Brewfile, the switch aborts and lists the offenders.
2. **Blocked command** — `modules/darwin/brew-lock.nix` shadows nix-homebrew's
   `brew` launcher on PATH with a shim that refuses to change state.
3. **No ambient brew** — Homebrew auto-update and brew shell integration stay
   disabled, so `/opt/homebrew/bin` never enters PATH, and switches never run
   `brew update` behind your back.

Read-only commands work through the shim, plus `upgrade` and `uninstall`.
`update` stays refused.

| Allowed | Refused |
| --- | --- |
| `brew list`, `info`, `search`, `desc`, `deps`, `uses`, `outdated`, `doctor`, `config`, `home`, `help`, `tap-info`, `leaves`, `cat`, `log`, `upgrade`, `uninstall`, `--prefix`, `--version`, `--cellar`, `--repository` | everything else, including `install`, `update`, `reinstall`, `tap`, `bundle`, `services`, `cleanup`, `shellenv` |

A refused command prints where to add the package instead.

### `upgrade` vs `update`

- `brew update` refreshes Homebrew's metadata: git taps and the JSON API.
  Under nix-homebrew it cannot work. Every activation creates a synthetic
  `$HOMEBREW_LIBRARY/.homebrew-is-managed-by-nix/.git` (with an empty `HEAD`)
  and points `HOMEBREW_REPOSITORY` at it, so there is no remote to fetch from,
  and Homebrew itself is a nix input — updating it means
  `nix flake update nix-homebrew`.
- Metadata freshness is handled separately. `homebrew.global.autoUpdate = false`
  sets `HOMEBREW_NO_AUTO_UPDATE=1`, which also freezes the API cache
  (`api.rb` treats it as never stale). `HOMEBREW_FORCE_API_AUTO_UPDATE=1` is set
  in `modules/darwin/homebrew.nix`, which refreshes cask data over plain HTTP
  and never touches the synthetic git repo.
- `brew upgrade` skips `auto_updates: true` casks unless `--greedy` is passed.
  Six of the eight declared casks are flagged `auto_updates` (obs, steam,
  orbstack, vorssaint, tailscale-app, helium-browser), so those update through
  their own updaters and brew leaves them alone. Only rustdesk and anydesk are
  brew-managed. Do not pass `--greedy`: it makes brew fight the apps' updaters.

### Recovery

When the drift check fails, the switch message lists the packages. Either:

- add them to `modules/darwin/homebrew.nix` (if they belong in the config), or
- remove them: `brew uninstall --cask <name>`, or `brew bundle cleanup --force`.

`uninstall` is allowed through the shim precisely for this. It self-heals: a
declared cask removed by mistake comes back on the next activation. `bundle`
itself is refused by the shim, so that form needs the real binary:
`/opt/homebrew/bin/brew bundle cleanup --force`. When the drift is an app that
was removed from the config (for example a migration from Discord to Vesktop),
the shim on the machine is still the old one, so the very first removal also
needs `/opt/homebrew/bin/brew uninstall --cask <name>`.

Nothing is ever deleted silently. `cleanup = "uninstall"` and `"zap"` exist but
are not used on purpose: `zap` also deletes an app's preferences, caches and
support files, which is not something a switch should do without asking.

### Honest limit

`/opt/homebrew/bin/brew` still exists and can be called by absolute path. It
cannot be permission-locked: nix-homebrew recreates it as a symlink to a
nix-store script on every activation, and `brew bundle` itself must run as
`zrie` during a switch. The drift check is what makes a bypassed install
impossible to keep — the next switch fails until it is resolved.

## Storage

The main machine is a MacBook Air, so the Nix store is kept on a leash.

### Weekly maintenance

`modules/darwin/core.nix`:

```nix
nix.gc.automatic = true;
nix.gc.interval  = [ { Weekday = 7; Hour = 3;  Minute = 15; } ];  # Sunday
nix.gc.options   = "--delete-older-than 15d";

nix.optimise.automatic = true;
nix.optimise.interval  = [ { Weekday = 7; Hour = 4;  Minute = 45; } ];

nix.settings.min-free = "40G";
nix.settings.max-free = "100G";
```

- GC removes generations older than 15 days, so rollback is possible for 15
  days (except the current generation, which is never removed).
- Store optimisation deduplicates identical files via hard links.
- Both run as launchd daemons. launchd rules for a missed run: if the Mac is
  **asleep** at 03:15, the job runs when it wakes; if the Mac is **powered off**
  at 03:15, the job is skipped and waits for the next Sunday. A weekly job can
  therefore be missed for a week on a laptop that is often shut down overnight.
  Switch the interval to daily (`{ Hour = 3; Minute = 15; }`, no `Weekday`) if
  that ever becomes a problem.

### Disk pressure safety net

`min-free` / `max-free` are the only mechanism that reacts to actual disk
pressure; the weekly jobs cannot. When free space drops below `min-free` **and**
Nix wants to build or substitute, Nix runs GC and deletes unreferenced paths
until free space reaches `max-free`, or nothing collectible is left. Notes:

- It is triggered by Nix activity, not by a background monitor. Filling the disk
  from other apps does not trigger it.
- GC here removes only unreferenced paths. Old generations are roots, so if the
  space is held by generations, this frees little — that is what the count cap
  below is for.
- Defaults are `min-free = 0` (disabled) and unlimited `max-free`.

### Capping generations by count

Nix has no "keep N generations" option; `--delete-older-than` is the only GC
retention control. To cap the count as well:

```sh
sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +10
sudo nix-env -p /nix/var/nix/profiles/per-user/zrie/profile --delete-generations +10
```

`+10` means "keep the newest 10, delete the rest". Two caveats: GC never removes
paths still rooted by a `result` symlink in a clone, and with home-manager
embedded here (driver version 1) there is no separate home-manager profile — the
system profile is the one that grows.

### Deliberately not used

- `nix.settings.auto-optimise-store` — nix-darwin asserts against it as known to
  corrupt the store. `nix.optimise.automatic` is the supported replacement.
- Rosetta Homebrew prefix (`nix-homebrew.enableRosetta = false`) — a second
  Homebrew tree for no current need.
- `linux-builder` VM — a whole Linux VM on disk; revisit only if darwin builds
  become painful.

### Homebrew disk use

`homebrew.onActivation.cleanup = "check"`, so `brew bundle` never deletes
anything by itself: casks installed outside the config make the next switch
abort instead, until they are added to the config or removed with
`brew bundle cleanup --force`. See the Homebrew policy above.

## Editing

### Values

`vars.nix` holds the only non-machine values: `username`, `gitUser`,
`gitEmail`. The git identity is a placeholder until filled in.

### Where a package goes

Preference order, top wins:

1. **Already in nixpkgs** → CLI tools go in `modules/home/packages.nix` or a
   dedicated module; GUI apps go in `profiles/workstation/system.nix`
   (`environment.systemPackages` — nix-darwin copies their app bundles into
   `/Applications/Nix Apps`).
2. **A pinned flake** → its own module, e.g. `modules/home/herdr.nix`
   (`inputs.<flake>.packages.<system>.default`).
3. **No usable nixpkgs/darwin package** → a Homebrew cask in
   `modules/darwin/homebrew.nix`. See the Homebrew policy above.

Verified platform support matters. Example: `ghostty` in nixpkgs is Linux-only,
so the macOS app comes from `ghostty-bin`; `obs-studio` is Linux-only, so obs is
a cask.

### Structure

```text
flake.nix        inputs + outputs (apps, checks, darwinConfigurations, homeConfigurations)
vars.nix         user values
lib/apps.nix     profile wrapper (host detection, guards, switch command)
lib/mk-host.nix  nix-darwin configuration for one host + profile
hosts/*.nix      machine facts: hostname, platform, user, home, profiles
profiles/<name>/ home.nix   home-manager content (cumulative imports)
profiles/<name>/ system.nix nix-darwin system content
modules/home/*   home-manager modules
modules/darwin/* nix-darwin modules
```

Profiles compose by importing the previous one: `agents` imports
`headless/home.nix`, `workstation` imports `agents/home.nix`. A host lists which
profiles it supports in `hosts/<host>.nix`; the flake generates one
`darwinConfiguration` per host/profile plus a dash-named mirror because
`darwin-rebuild` cannot address attribute names containing a dot.

### Checks

`--dry-run` (or `-n`) on any profile app means "build, do not activate": the
wrapper maps it to `darwin-rebuild build`, `nixos-rebuild build` or
`home-manager build`. Upstream `darwin-rebuild --dry-run` is unusable — it
passes `--dry-run` to `nix build` and then runs `nix-env --set` on the unbuilt
path, which fails with "don't know how to build these paths".

Any machine:

```sh
nix flake check --no-build
nix eval .#darwinConfigurations."unit-05.workstation".config.system.build.toplevel.drvPath
nix build .#homeConfigurations."zrie@linux-x86_64-headless".config.home.activationPackage
```

On Linux the profile wrapper script itself also builds and is shellchecked:

```sh
nix flake check          # builds checks for the current system only
```

Darwin configurations can only be evaluated on Linux, not built. `nix flake
check` skips incompatible systems by design; `--all-systems` would try to build
them and fail without a darwin builder.

### Secrets

`~/.config/sops/age/keys.txt` is generated per machine on first switch. A new
machine gets a new key, so existing sops secrets are only decryptable where the
matching key is present. Sharing secrets across machines needs a separate
key-distribution decision.

## Fonts

`packages/lilex-nerd-font.nix` patches Lilex from the upstream release with the
Nerd Fonts patcher, mono variant, all 14 static styles, and
`modules/darwin/fonts.nix` installs the result through nix-darwin
`fonts.packages` into `/Library/Fonts/Nix Fonts` (workstation profile only).

Why not `nerd-fonts.lilex` from nixpkgs: that is the Nerd Fonts v3.5.0 bundle
with Lilex 2.700 (2026-04-04), while upstream 2.630 is from 2026-10-05. Lilex's
version numbers are not monotonic, so compare release dates, not tags. The
bundle also ships 10 styles and skips Light and SemiBold.

To bump: change `version` and the `hash` in `packages/lilex-nerd-font.nix`
(`nix store prefetch-file <url>` prints the SRI hash). The patcher warns that
fontforge 20251009 "produces unusable fonts in some cases"; if glyphs come out
broken, pin an older `fontforge` in that file.

`modules/home/ghostty.nix` writes `~/.config/ghostty/config.ghostty` with
`font-family = Lilex Nerd Font Mono`. Ghostty loads the XDG file first and the
`~/Library/Application Support/com.mitchellh.ghostty/*` files after it, so a
config there would win.

## Prompt (starship)

The agents profile enables starship with **no** `settings` and no `presets`. That
is deliberate: home-manager writes `~/.config/starship.toml` only when one of
those is set, and exports `STARSHIP_CONFIG` either way, so the file stays loose
and the prompt can be explored without a switch per try:

```sh
starship preset --list
starship preset tokyo-night -o ~/.config/starship.toml
```

When the config stops changing, declare it in `profiles/agents/home.nix`:

- `programs.starship.presets = [ "tokyo-night" ];` — home-manager merges the
  shipped preset itself, later entries winning.
- `programs.starship.settings = builtins.fromTOML (builtins.readFile ../../config/starship.toml);`
  — keeps the tweaked TOML in the repo as the source of truth.

Either way home-manager takes the file over and the loose one is moved aside as
`starship.toml.hm-backup`. Symbol-heavy presets need a Nerd Font in the
terminal. While starship is on, the plain `PROMPT` in `modules/home/zsh.nix` is
skipped (`lib.mkIf (!config.programs.starship.enable)`) because starship resets
the prompt on every `precmd`.
