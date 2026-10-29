# Entryplug

Layer between me and my machine. Load anywhere, anytime. Powered by Nix.

## Profiles

Profiles are cumulative and selected when you switch:

| Profile       | Contents                                                                                                                                                                 |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `headless`    | CLI tools, bash (Linux) / zsh (macOS), vim, git, fzf, tmux, sops/age                                                                                                     |
| `agents`      | `headless` + pi (with extensions), herdr, node 26 + bun, starship prompt, modern shell tools (zoxide, eza, bat, fd, ripgrep-all, btop, gh, lazygit, tldr, neovim), nvim as `$EDITOR` |
| `workstation` | `agents` + ani-cli, mpv (CLI), Lilex Nerd Font Mono (patched from upstream) from nixpkgs; ghostty config; bitwarden, firefox, ghostty from nixpkgs; helium, vesktop, vlc, obs, steam, orbstack, vorssaint, rustdesk, anydesk, tailscale via Homebrew casks |
| `desktop`     | not implemented (NixOS-only, future)                                                                                                                                     |

Default profile is `headless`. List available hosts under [`hosts/`](./hosts/).

## Install

### VM / guest OS

Any Linux distro, `curl` and `sh`:

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon

sudo mkdir -p /etc/nix
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf

nix run github:zrierc/entryplug#headless
```

The wrapper detects the architecture and whether the machine is NixOS. On
NixOS it runs `nixos-rebuild`; anywhere else it runs standalone `home-manager`.

### macOS

> [!IMPORTANT]
> Required to have same account and hostname same. Adjust it under [`hosts/*.nix`](./hosts/)

Prerequisites:

1. Nix installed with flakes enabled:

   ```sh
   sh <(curl -L https://nixos.org/nix/install) --daemon

   sudo mkdir -p /etc/nix
   echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
   ```

2. Roughly 15–20 GB free disk: pi and herdr compile from source on the first
   switch (20–40 minutes).

Run this in a graphical terminal, not over SSH: macOS asks for App Management
permission during the first activation, and a TCC prompt can abort an SSH
switch.

```sh
nix run github:zrierc/entryplug -- --dry-run   # build only, activates nothing
nix run github:zrierc/entryplug                # first switch (headless)
nix run github:zrierc/entryplug#agents
nix run github:zrierc/entryplug#workstation
```

`--dry-run` builds the whole system configuration and stops before activation.
It is not passed through to `darwin-rebuild --dry-run`, which is broken upstream
(it still runs `nix-env --set` on a path it never built).

Until the GitHub repo exists, run the same commands from a local clone with
`.#` instead of `github:zrierc/entryplug`.

## Switching

Same commands as above; any profile can be reapplied at any time.

```sh
nix run github:zrierc/entryplug#workstation    # or .#workstation from a clone
darwin-rebuild switch --flake .#unit-05-headless
```

Rollback: `darwin-rebuild --list-generations`, then `darwin-rebuild --rollback`.

## Docs

- [Operations](docs/operations.md) — Homebrew policy, storage, editing, secrets.
