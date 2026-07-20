# cod-clients-nix

<!-- BEGIN generated:badges -->
[![CI](https://github.com/Daaboulex/cod-clients-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/Daaboulex/cod-clients-nix/actions/workflows/ci.yml)
[![NixOS unstable](https://img.shields.io/badge/NixOS-unstable-78C0E8?logo=nixos&logoColor=white)](https://nixos.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
<!-- END generated:badges -->

Call of Duty custom clients packaged for NixOS - a Home Manager launcher module that runs Plutonium and t7x under umu-launcher + Proton, keeping each client current from its own official source, and optionally links Plutonium into Steam so it tracks your hours.

<!-- BEGIN generated:upstream -->
## Upstream

| | |
|---|---|
| **Project** | Plutonium (plutonium.pw) + t7x (alterware.dev) - runtime-fetched, self-updating |
| **License** | Proprietary / third-party clients (packaging is MIT) |
| **Tracked** | None - the official clients self-update at runtime |

<!-- END generated:upstream -->

## What Is This?

A Nix flake that launches community Call of Duty clients on Linux without hand-rolling a Wine prefix. It provides three commands:

- **`cod-plutonium`** - standalone launcher for Black Ops 1 (T5), Black Ops 2 (T6), Modern Warfare 3 (IW5), World at War (T4). Fetches the official self-updating `plutonium.exe`, bootstraps a Proton prefix with the required winetricks verbs, and launches under umu-launcher.
- **`cod-t7x`** - standalone launcher for Black Ops III (T7). Fetches the official self-updating `t7x.exe` and runs it against a symlink-farm of your owned retail BO3 install.
- **`cod-steamlink`** - optional helper that swaps a Steam game's exe for Plutonium so **Steam launches it on "Play" and tracks your hours**, safely and reversibly.

The client binaries are fetched at runtime into a per-client state directory and maintain themselves from their own official servers on every launch - the flake never pins, re-hosts, or freezes a game payload. You bring the games: each client mods a copy you legitimately own on Steam.

## Clients

| Command | Titles | Base game (own on Steam) | Notes |
|---|---|---|---|
| `cod-plutonium` | BO1, BO2, MW3, WaW | 202970 (BO2), 42700 (BO1), 10090 (WaW), 42750 (free MW3 route) | Standalone umu launcher; point Plutonium at the Steam folder in its UI |
| `cod-t7x` | BO3 | 311210 (Black Ops III) | Standalone; experimental on Linux (see Caveats) |
| `cod-steamlink` | BO2 (default) + any Plutonium title | as above | Steam hours-tracking via a reversible exe-swap |

## Home Manager Module

The repo exports `homeManagerModules.default`. Options:

```nix
myModules.home.codClients = {
  enable = true;                         # master switch
  protonPath = "${pkgs.proton-ge-bin.steamcompattool}";  # default: pinned nixpkgs GE-Proton
  plutonium = {
    enable = true;                       # cod-plutonium + cod-steamlink
    dotnet = false;                      # opt-in MW3/IW5 support (installs dotnet472)
    extraWinetricks = [ ];               # extra prefix verbs
    extraArgs = [ ];                     # extra plutonium.exe args (LAN etc.)
  };
  t7x = {
    enable = true;                       # cod-t7x
    blackOps3Dir = "";                   # empty = auto-detect from Steam
    extraWinetricks = [ ];               # e.g. [ "mf" "mfplat" ] for codec issues
    extraArgs = [ ];
  };
};
```

- **`protonPath`** is what umu runs the clients under. The default pins nixpkgs GE-Proton reproducibly (its `steamcompattool` output). If you manage Proton with ProtonPlus and would rather reuse it, set this to that directory, e.g. `"${config.home.homeDirectory}/.steam/steam/compatibilitytools.d/GE-Proton10-34"`.
- **`plutonium.dotnet`** adds `dotnet472` for MW3/IW5. It is off by default because the install is slow and MW3/IW5 has an unfixed no-cursor bug on NixOS + GE-Proton; BO1/BO2/WaW do not need it.
- **`t7x.blackOps3Dir`** empty auto-detects Black Ops III (app 311210) from Steam - see Store detection.

## Steam hours-tracking

Plutonium runs on non-VAC servers and never touches the retail Steam client, so launching it does not risk a VAC ban - but by default it runs outside Steam, so Steam does not count the time. `cod-steamlink` wires it into Steam the way the community does it: it renames a game's launch exe and drops `plutonium.exe` in its place, so Steam's "Play" opens Plutonium and tracks the hours under that game.

```bash
cod-steamlink                       # default: Black Ops II (app 202970, t6mp.exe)
cod-steamlink --appid N --exe NAME  # a different title/exe
cod-steamlink --undo                # restore the original exe
```

It resolves the game directory (see below), backs up the original exe to `<exe>.cod-orig`, copies in the fetched `plutonium.exe`, marks it read-only, and prints the one command you run yourself to make it survive Steam auto-updates:

```bash
sudo chattr +i "<path>/t6mp.exe"
```

`--undo` restores the backup. Because Plutonium's launcher lets you pick any title, one swap (e.g. Black Ops II) is enough to track all your Plutonium hours under that game.

## Store detection

`cod-t7x` and `cod-steamlink` locate your games from Steam's own metadata, so a game on any drive is found. They scan every Steam install layout - native (`~/.steam/steam`, `~/.local/share/Steam`), Flatpak (`~/.var/app/com.valvesoftware.Steam`), and Snap (`~/snap/steam`) - and read each one's `steamapps/libraryfolders.vdf` to follow **moved and additional library folders** to the app's `appmanifest_<id>.acf`. If detection ever misses, pass an explicit path (`t7x.blackOps3Dir`, or `cod-steamlink --dir`).

## Caveats

- **You must own the games** on Steam. These launchers mod games you own; they do not provide the base game.
- **t7x / BO3 is experimental on Linux**: upstream does not test Linux and there are reports of a GStreamer/Media-Foundation codec error under Proton with no confirmed fix. If you hit it, try `t7x.extraWinetricks = [ "mf" "mfplat" ]`.
- **Plutonium online play** needs a free Plutonium forum account and the latest revision (the client self-updates to it).

<!-- BEGIN generated:installation -->
## Installation

Add as a flake input:

```nix
{
  inputs.cod-clients = {
    url = "github:Daaboulex/cod-clients-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

<!-- END generated:installation -->

## Usage

```nix
# 1. flake input (above), then wire the module into the host:
home-manager.sharedModules = [ inputs.cod-clients.homeManagerModules.default ];

# 2. enable it in the host HM config:
myModules.home.codClients = {
  enable = true;
  plutonium.enable = true;
  t7x.enable = true;
};
```

After a rebuild, launch `cod-plutonium` / `cod-t7x` from your application menu, or run `cod-steamlink` once to play through Steam with hours-tracking. Log in with your client account on first launch.

## Development

```bash
nix develop      # dev shell (git hooks + nil LSP)
nix fmt          # format Nix (nixfmt-rfc-style)
nix build .#cod-plutonium
nix build .#cod-t7x
nix build .#cod-steamlink
nix flake check  # eval + build + std-conformance + module eval
```

## CI/CD

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | Push/PR | Eval, format, build every declared output |
| `maintenance.yml` | Weekly | Refresh `flake.lock`, prune stale branches |

All GitHub Actions are pinned to full commit SHAs, synced from the Nix Packaging Standard.

<!-- BEGIN generated:footer -->
---

*Maintained as part of the [Daaboulex](https://github.com/Daaboulex) NixOS ecosystem.*
<!-- END generated:footer -->
