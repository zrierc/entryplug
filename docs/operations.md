# Operations

## Homebrew policy

Homebrew exists here for one reason: a few GUI apps have no usable nixpkgs
`aarch64-darwin` package. Everything else comes from nixpkgs or a pinned flake.
Brew is treated as a cask installer that belongs to the configuration, not as a
package manager you use by hand.

Casks live in `modules/darwin/homebrew.nix`. Current list: karabiner-elements,
obs, steam, orbstack, vorssaint, rustdesk, anydesk, tailscale-app,
helium-browser, vesktop, vlc.

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

1. **Declared list is the only source of truth** —
   `homebrew.onActivation.cleanup = "uninstall"`. During `darwin-rebuild switch`
   nix-darwin runs `brew bundle --force-cleanup`, which deletes every tap,
   formula and cask that is not in the generated Brewfile. Removing a line from
   the config removes the package on the next switch.
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
  Every declared cask except rustdesk and anydesk is flagged `auto_updates`, so
  those update through their own updaters and brew leaves them alone; only
  rustdesk and anydesk are brew-managed. Do not pass `--greedy`: it makes brew
  fight the apps' updaters.

### Drift and removals

`cleanup = "uninstall"` means brew deletes anything undeclared, without asking.
What that covers:

- **Removed from the config** — the app goes away on the next switch. Nothing to
  do by hand.
- **Installed outside the config** — also deleted. This is the intended
  behaviour here, since `install`, `tap` and `bundle` are refused by the shim,
  so hand installs are the exception. It also removes undeclared formulae,
  including ones pulled in as dependencies of a hand-installed formula.

To preview what would be deleted, list it without `--force`. The generated
Brewfile path is exported as `HOMEBREW_BUNDLE_FILE`, so the shim's refusal of
`bundle` means the real binary is needed for this one:

```sh
/opt/homebrew/bin/brew bundle cleanup
```

The shim allows `uninstall` for the case where you want to remove something
right away; a declared cask removed by mistake comes back on the next
activation, so it self-heals. `zap` is deliberately not used: it would also
wipe the app's preferences, caches and support files.

### Honest limit

`/opt/homebrew/bin/brew` still exists and can be called by absolute path. It
cannot be permission-locked: nix-homebrew recreates it as a symlink to a
nix-store script on every activation, and `brew bundle` itself must run as
`zrie` during a switch. What makes a bypassed install pointless is
`cleanup = "uninstall"`: the next switch deletes whatever the declared list does
not contain.

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

`homebrew.onActivation.cleanup = "uninstall"` keeps the Homebrew side at exactly
the declared set: casks installed outside the config are deleted on the next
switch, and `brew bundle` never upgrades what is already there. See the Homebrew
policy above.

## Editing

### Values

`hosts/<host>.nix` is the only place machine facts live: hostname, platform,
primary user, home directory and the supported profiles. That user name is
reused for the generic Linux `homeConfigurations`, which have no host entry of
their own. The git identity is not a Nix value: `modules/home/git.nix` writes
it from the secret manager at activation, and the private keys are restored
from the same place by hand. See Git below.

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
lib/apps.nix     profile wrapper (host detection, guards, switch command)
lib/mk-host.nix  nix-darwin configuration for one host + profile
hosts/*.nix      machine facts: hostname, platform, user, home, profiles
profiles/<name>/ home.nix   home-manager content (cumulative imports)
profiles/<name>/ system.nix nix-darwin system content
modules/home/*   home-manager modules
modules/darwin/* nix-darwin modules
config/*         raw app config the modules read or link (nvim, starship, herdr)
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

`secrets/secret.yaml` is sops-encrypted to the age recipient in `.sops.yaml`
and holds the git identities plus the provider API keys.

The private half lives at `~/.config/sops/age/keys.txt`. It is not in the repo,
so every new machine needs it restored by hand from the secret manager.
`modules/home/secrets.nix` generates a key when the file is missing, but a
generated key cannot decrypt an existing secret, so that file is a placeholder
to overwrite. Without the real key, activation warns and the git identities
stay unwritten; the switch itself still completes.

## Git

Each directory under `~/Dev` has its own account. The directory decides the
commit identity and the ssh key, and the remote stays a plain
`git@github.com:owner/repo`:

| Directory        | Identity   | ssh key          |
| ---------------- | ---------- | ---------------- |
| `~/Dev/works`    | `work`     | `github_primary` |
| `~/Dev/college`  | `college`  | `github_college` |
| `~/Dev/personal` | `personal` | `github_primary` |
| `~/Dev/projects` | `personal` | `github_primary` |
| `~/Dev/learn`    | `personal` | `github_primary` |

`modules/home/git.nix` generates one `includeIf` block per directory: the first
sets `core.sshCommand` to `ssh -i <key> -o IdentitiesOnly=yes`, the second
points at the identity file. The trailing slash makes the pattern cover
everything below the directory, submodules included. `IdentitiesOnly=yes` means
the directory's key is the only one tried, so a repository on another host
inside `~/Dev/college` fails instead of falling back to another account.

No `Host` aliases are involved: the remote stays `git@github.com:...` and the
key is chosen per directory, so nothing in the ssh config has to be maintained.
A repository cloned through an old alias keeps working through its own `Host`
block. A per-repo override is the ordinary local `git config user.email`, which
wins over the include.

Identities come from `git.work`, `git.college` and `git.personal` in the secret
manager and are written at activation into `~/.config/git/identities/<id>.inc`
at 0600. A missing age key, or a key missing from the secret, produces a warning
and no file — never a partial file or a `null` value.

Private keys are plain files under `~/.ssh/key` at 0600 and are deliberately not
repo secrets. A private key in git history can never be removed, and storing all
three accounts behind the age key would make one leaked file enough to push as
anyone. Each account has exactly one key, so `work` and `personal` share
`github_primary`, and the key name above is also the file name.

New machine, in order:

1. Install Nix and run the profile apps. The flake is fetched over HTTPS, so the
   switches themselves need no git credentials; a private repo would need a
   token for this step.
2. Restore `~/.config/sops/age/keys.txt` and `~/.ssh/key/github_primary` plus
   `github_college` from the secret manager, keys at 0600.
3. Switch once more: the identities are written and the warnings stop.
4. Clone with `git@github.com:...`. The directory decides which key and which
   identity the repository uses.

Rotation: revoke the old public key at the host, replace the private key in the
secret manager, copy the new file to `~/.ssh/key`. Nothing in the repo changes,
because the repo never held the key.

## Keyboard

Caps Lock is the escape key when tapped and control when held, and the escape
key is Caps Lock. Both platforms use the same mapping, with different tools.

### macOS (Karabiner-Elements)

Karabiner comes from the Homebrew cask, not nixpkgs. It needs a DriverKit
virtual-HID system extension and privileged daemons; the nixpkgs package ships
the driver as a separate output and rewrites the daemon plists to point into
the store, so its app bundle is not a drop-in replacement for the official
installer. This is the one cask in the list whose nixpkgs package exists and is
deliberately not used.

`config/karabiner.json` is linked read-only to `~/.config/karabiner/karabiner.json`.
Karabiner writes that file whenever anything is changed in its own UI, so the
GUI cannot save edits — same rule as the herdr config: change the repo file and
switch. The rule language: `to_if_alone` fires on release when no other key was
pressed, `to` holds while the key is down.

Four permissions are granted by hand on first run, from System Settings:
background services (and Karabiner must stay enabled in "Allow in the
Background"), Accessibility, Input Monitoring, and the driver extension.
Closing the settings window is fine — the menu bar app and the daemons keep
running; quitting from the menu bar turns the remap off.

The Caps Lock LED is no longer driven by the physical key, because the key no
longer sends `caps_lock`. Whether the LED follows when escape sends `caps_lock`
is worth checking on the machine. `basic.to_if_alone_timeout_milliseconds` is
1000: a tap released within a second with no other key becomes escape, anything
else is control.

Resource notes: idle cost is small, but the privileged core service has a
history of slow memory growth (an issue filed against 15.7.0 measured about
10MB/day). If it climbs, quit and reopen Karabiner from the menu bar. A mouse
with an extreme polling rate has also been reported to pin the grabber at 100%
CPU.

### Linux (keyd)

`config/keyd/default.conf` is the same mapping in keyd syntax:

```conf
[main]
capslock = overload(control, esc)
esc = capslock
```

It is committed but not wired. keyd grabs input devices directly and needs
root, so it belongs to a system layer: home-manager has no keyd module, and this
repo's Linux side is standalone home-manager with no `nixosConfigurations`.
When the `desktop` profile lands, this file goes to `services.keyd` in the
NixOS configuration.

Until then, per machine: install keyd, copy the file to
`/etc/keyd/default.conf`, start the daemon. Validate the syntax without root or
a reboot first:

```sh
keyd check config/keyd/default.conf
```

`overload(control, esc)` is hold/tap in one binding; unlike Karabiner it has no
timeout, so a tap is always escape and a hold is always control.

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

## Comment style

Comments explain **why**, never what the code does, and are English only.

Keep:

- non-obvious upstream behaviour, such as why `darwin-rebuild --dry-run` cannot
  be passed through,
- trade-offs behind a choice, such as why eza's aliases are forced key by key or
  why starship gets no settings,
- platform side effects the code cannot show, such as ghostty's config load
  order.

Delete:

- restatements of the line below (`# Storage: weekly GC ...` above `nix.gc`),
- stale package lists inside comments,
- commented-out code.

One deliberate exception: the `font-feature` lines in `modules/home/ghostty.nix`
are commented config meant to be uncommented in place.

## Neovim

`config/nvim` is a LazyVim checkout. `modules/home/nvim.nix` links `init.lua`,
`lua/`, `stylua.toml` and `.neoconf.json` into `~/.config/nvim` as read-only
store symlinks, one entry per file, so the directory itself stays a real
directory and anything not declared there can still be written.

That read-only config is what makes the two Lua changes necessary. Both files
below are written *next to `init.lua`* by default, and both writers would fail
on a store symlink, so each is repointed at `stdpath("data")`:

| File | Default | Now | Set in |
| --- | --- | --- | --- |
| `lazy-lock.json` | `stdpath("config")` | `~/.local/share/nvim/lazy-lock.json` | `config/nvim/lua/config/lazy.lua`, lazy.nvim's `lockfile` option |
| `lazyvim.json` | `stdpath("config")` | `~/.local/share/nvim/lazyvim.json` | `config/nvim/init.lua`, `vim.g.lazyvim_json` |

Consequences worth knowing:

- Plugin pins live outside the repo, so they are per-machine and not shared
  between hosts. Delete `~/.local/share/nvim/lazy-lock.json` to let lazy.nvim
  re-pin from whatever is currently checked out.
- `:LazyExtras` writes to the relocated `lazyvim.json` and works normally.
- Adding a plugin means editing `config/nvim/lua/plugins/` in the repo and
  switching. Creating a file from inside `nvim` fails, because `lua/` is
  read-only.
- LazyVim's bootstrap still clones lazy.nvim into `~/.local/share/nvim/lazy`,
  so a fresh machine needs `git` on PATH and a network connection on first
  start. That directory is untouched by home-manager.

Deliberately not managed: the LazyVim starter's `LICENSE`, `README.md` and
`.gitignore`, and the two state files named above. The starter `.gitignore` in
particular must not be copied into the repo — a nested `.gitignore` would
silently change git's ignore rules for the whole `config/nvim` subtree.

## herdr

`config/herdr.toml` is linked to `~/.config/herdr/config.toml` read-only, which
has one visible consequence: `herdr config reset-keys` rewrites and backs up
that file, so it cannot work. Edit the repo file and switch, then apply it to a
running server with `herdr server reload-config` (there is a `reload_config` key
action too), or validate it first with `herdr config check`.

Everything else in `~/.config/herdr` is herdr's own runtime state and is left
alone: `session.json`, `.plugins.lock`, the client and server logs, the two
sockets and `session-snapshots/`. `default.toml` is the annotated reference
config, embedded in the herdr binary and written back on demand — it is not user
config and is not tracked here.

herdr is a pinned flake input rather than a nixpkgs package because its config
keys are version-specific; this repo declares `v0.9.3`. `herdr update` downloads
and installs its own build outside the nix store, which would leave two herdr
binaries on the machine with the store one still winning on PATH. To change
version, bump `inputs.herdr` in `flake.nix`.

## Prompt (starship)

`config/starship.toml` is the source of truth. `profiles/agents/home.nix` reads
it with `builtins.fromTOML` and hands it to `programs.starship.settings`, so
home-manager generates `~/.config/starship.toml` and exports `STARSHIP_CONFIG`
pointing at it.

starship only reads `$STARSHIP_CONFIG` or `$XDG_CONFIG_HOME/starship.toml`. It
never looks in a `starship/` subdirectory, which is why the file lives at that
path and not `~/.config/starship/starship.toml`.

The file is `starship print-config` output: 109 module tables, each one mostly
restating the value its module already has. The top-level globals were stripped
before it was committed, because every one of them was a verbatim copy of the
built-in default:

| Dropped | Built-in default |
| --- | --- |
| `format` | `"$all"` |
| `right_format` | `""` |
| `continuation_prompt` | `"[∙](bright-black) "` |
| `scan_timeout` | `30` |
| `command_timeout` | `500` |
| `add_newline` | `true` |
| `follow_symlinks` | `true` |

Removing them changes nothing, and `format` is the one worth being clear about:
`"$all"` *is* the default, not an opt-in. Deleting it does not shorten the
prompt. `starship print-config` prints the effective config including these
defaults, which is where the comparison above comes from.

`$schema` is kept so an editor can complete the file.

Exactly one key in the whole file differs from what a stock starship would emit:

| Key | Repo | Stock | Effect |
| --- | --- | --- | --- |
| `nix_shell.symbol` | `"❄️ "` | `"❄️  "` | One trailing space instead of two |

`nix_shell.heuristic` deserves a note even though it sits at its default
(`false`). It is not a directory check. When `IN_NIX_SHELL` is unset it scans
`$PATH` for any entry starting with `/nix/store` and, on a match, renders the
module in the `Unknown` state. This machine's PATH has three such entries
(nodejs, fd, ripgrep), so turning it on shows the segment in every directory,
and because `unknown_msg` is `""` it shows up as a bare `❄️` with no label.
Leave it `false`.

Everything else is the default restated, so tuning the prompt means editing
module tables, not globals. For a shorter prompt, set `format` explicitly to the
segments you want, or set the ones you do not want to `disabled = true`.

Editing rules:

- Change `config/starship.toml`, never `~/.config/starship.toml`, which is a
  read-only store symlink after activation.
- Comments do not survive. `fromTOML` parses them away, so the generated file is
  values only. Keep reasoning in the repo file and here.
- Table order in the generated file is the TOML generator's, not the repo
  file's. A round trip through Nix is verified value-identical; the generated
  file is smaller only because comments and blank lines are gone.
- Modules that draw symbols need a Nerd Font in the terminal. Only the
  workstation profile installs Lilex, so segments can render as boxes over SSH
  or on a bare headless machine.

While starship is on, the plain `PROMPT` in `modules/home/zsh.nix` is skipped
(`lib.mkIf (!config.programs.starship.enable)`) because starship resets the
prompt on every `precmd`.
