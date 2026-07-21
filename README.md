# cod-clients-nix

<!-- BEGIN generated:badges -->
[![CI](https://github.com/Daaboulex/cod-clients-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/Daaboulex/cod-clients-nix/actions/workflows/ci.yml)
[![NixOS unstable](https://img.shields.io/badge/NixOS-unstable-78C0E8?logo=nixos&logoColor=white)](https://nixos.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
<!-- END generated:badges -->

Call of Duty custom clients packaged for NixOS - a Home Manager launcher module that runs Plutonium, t7x, and the AlterWare family under umu-launcher + Proton, each confined in a bubblewrap sandbox with access to only game-related files, and optionally links Plutonium into Steam so it tracks your hours.

<!-- BEGIN generated:upstream -->
## Upstream

| | |
|---|---|
| **Project** | Plutonium (plutonium.pw) + t7x (alterware.dev) - runtime-fetched, self-updating |
| **License** | Proprietary / third-party clients (packaging is MIT) |
| **Tracked** | None - the official clients self-update at runtime |

<!-- END generated:upstream -->

## What Is This?

A Nix flake that launches community Call of Duty clients on Linux without hand-rolling a Wine prefix. Launchers:

- **`cod-plutonium`** - Black Ops 1 (T5), Black Ops 2 (T6), Modern Warfare 3 (IW5), World at War (T4). Fetches the official self-updating `plutonium.exe`, bootstraps a Proton prefix with the required winetricks verbs, and launches under umu-launcher.
- **`cod-t7x`** - Black Ops III (T7). Fetches the official self-updating `t7x.exe` and runs it against a symlink-farm of your owned retail BO3 install.
- **`cod-h1`** - Modern Warfare Remastered (Aurora h1-mod). Fetches the self-updating `h1-mod.exe` and runs it against a symlink-farm of your owned MWR install. Default-off, experimental.
- **`cod-h2`** - MW2 Campaign Remastered (Aurora h2-mod). Self-updating `h2-mod.exe` against a symlink-farm of your owned MW2CR install. Default-off, experimental.
- **`cod-iw5` / `cod-iw6` / `cod-s1` / `cod-iw2`** - the AlterWare family: Modern Warfare 3 (2011), Ghosts, Advanced Warfare, and Call of Duty 2. Each uses the native `alterware-launcher` to update the client into your owned Steam install, then launches it under umu. Default-off and experimental (see Caveats).
- **`cod-hmw`** - Horizon MW (Modern Warfare Remastered mod). Self-updating launcher that downloads the mod into a symlink-farm of your owned MWR install. Default-off, experimental.
- **`cod-boiii`** - BOIII client (Black Ops III). Drop-in self-updating client that runs against a symlink-farm of your owned BO3 install. Default-off, experimental — DXVK rendering is untested on Linux (dedicated-server mode works under Wine).
- **`cod-cblauncher`** - CB Launcher hub for community CoD clients (17 supported titles). Works with Steam-installed games. Default-off, experimental.
- **`cod-steamlink`** - optional helper that swaps a Steam game's exe for Plutonium so **Steam launches it on "Play" and tracks your hours**, safely and reversibly.
- **`cod-steam-add`** - optional helper that registers every installed launcher as a Steam **non-Steam shortcut** (like Heroic's "Add to Steam"), so each shows in Steam, tracks hours, and takes per-shortcut launch options + Proton. Reversible (`remove`), sandbox preserved.
- **`cod-cleanops`** - optional helper that drops the CleanOps `d3d11.dll` into your owned retail Black Ops III, so launching BO3 through Steam loads CleanOps (cheat-removal + P2P hosting). Set the printed `WINEDLLOVERRIDES` launch option; reversible (`--undo`).
- **`cod-steam-native`** - registers the set-up clients as Steam shortcuts that run their `.exe` under **Steam's own Proton** (so the Compatibility dropdown works), reusing each client's prepared prefix. Plutonium gets one shortcut per owned game+mode (launches straight in via `plutonium://`); sets GE-Proton and fetches official cover art. Reversible (`remove`).

Every launcher runs inside a **bubblewrap sandbox** (see Security). The live client binaries are fetched at runtime into a per-client state directory and maintain themselves from their own official servers - the flake never pins, re-hosts, or freezes a game payload. You bring the games: each client mods a copy you legitimately own on Steam.

## Clients

| Command | Titles | Base game (own on Steam) | Notes |
|---|---|---|---|
| `cod-plutonium` | BO1, BO2, MW3, WaW | 202970 (BO2), 42700 (BO1), 10090 (WaW), 42750 (free MW3 route) | Standalone umu launcher; point Plutonium at the Steam folder in its UI |
| `cod-t7x` | BO3 | 311210 (Black Ops III) | Standalone; experimental on Linux (see Caveats) |
| `cod-h1` | MWR | 393080 (Modern Warfare Remastered) | Aurora h1-mod; farm + self-updating client; experimental, default-off |
| `cod-h2` | MW2CR | 1213210 (MW2 Campaign Remastered) | Aurora h2-mod; farm + self-updating client; experimental, default-off |
| `cod-steamlink` | BO2 (default) + any Plutonium title | as above | Steam hours-tracking via a reversible exe-swap |
| `cod-steam-add` | all installed launchers | - | Adds each launcher to Steam as a non-Steam shortcut; Proton + launch options per shortcut |
| `cod-cleanops` | BO3 retail MP | 311210 (Black Ops III) | Drops CleanOps d3d11.dll into owned BO3 (cheat-removal + P2P); launch via Steam |
| `cod-iw5` | Modern Warfare 3 (2011) | 115300 | AlterWare; experimental, default-off |
| `cod-iw6` | Ghosts | 209160 | AlterWare; experimental, default-off |
| `cod-s1` | Advanced Warfare | 209650 | AlterWare; experimental, default-off |
| `cod-iw2` | Call of Duty 2 | 2630 | AlterWare; experimental, default-off |
| `cod-hmw` | MWR | 393080 | Horizon MW; farm + self-updating launcher; experimental, default-off |
| `cod-boiii` | BO3 | 311210 | BOIII; farm + self-updating client; experimental, default-off |
| `cod-cblauncher` | 17 CoD titles | - | CB Launcher hub; experimental, default-off |

## Home Manager Module

The repo exports `homeManagerModules.default`. Options:

```nix
myModules.home.cod-clients = {
  enable = true;                         # master switch
  sandbox = true;                        # bubblewrap: game-only access (default on)
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
  alterware = {                          # experimental, default-off
    iw5.enable = false;                  # Modern Warfare 3 (2011)
    iw6.enable = false;                  # Ghosts
    s1.enable = false;                   # Advanced Warfare
    iw2.enable = false;                  # Call of Duty 2
  };
  hmw = {                                # experimental, default-off
    enable = false;                      # Horizon MW (MWR mod)
    mwrDir = "";                         # empty = auto-detect from Steam (app 393080)
    extraArgs = [ ];
  };
  boiii = {                              # experimental, default-off
    enable = false;                      # BOIII client (BO3)
    blackOps3Dir = "";                   # empty = auto-detect from Steam (app 311210)
    extraArgs = [ ];
  };
  cblauncher = {                         # experimental, default-off
    enable = false;                      # CB Launcher hub
  };
};
```

- **`protonPath`** is what umu runs the clients under. The default pins nixpkgs GE-Proton reproducibly (its `steamcompattool` output). Set it to a ProtonPlus-managed Proton path to reuse that, or to `"steam"` to auto-detect the newest Proton in your Steam `compatibilitytools.d`. To change Proton **on the fly**, set `COD_PROTON=<path>` per launch (e.g. `COD_PROTON=~/.steam/steam/compatibilitytools.d/GE-Proton10-34 cod-plutonium`). The `cod-steamlink` path instead uses Steam's own per-game Compatibility dropdown.
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

## Add to Steam (any Proton, launch options)

`cod-steam-add` registers every installed `cod-*` launcher as a non-Steam shortcut - the Heroic-style "Add to Steam", done for you:

```bash
cod-steam-add          # add all installed launchers (close Steam first)
cod-steam-add list     # show which are registered
cod-steam-add remove   # remove them again
```

Close Steam before adding (it rewrites `shortcuts.vdf` on exit); the helper backs up that file, only ever touches its own tagged entries, and never clobbers your other shortcuts. Restart Steam afterwards.

Each shortcut points at the launcher - so it keeps the bubblewrap sandbox, the winetricks prefix, and the runtime client-fetch. That means **Proton is chosen per shortcut in Steam's Launch Options, not the Compatibility dropdown**: Steam's forced-Proton only drives a raw Windows `.exe` and would break a native launcher script. Set a specific Proton with `COD_PROTON=/path/to/proton %command%` in the shortcut's Launch Options (or leave it to `protonPath`). Launch options and Steam playtime work as normal.

## Steam-native (Proton dropdown + per-mode)

`cod-steam-native` is the other side of that trade-off: instead of the native launcher (where the Compatibility dropdown can't apply), it registers each client's **Windows `.exe`** so Steam runs it under its own Proton and **the dropdown works**. It reuses each client's already-prepared prefix - so Plutonium keeps its winetricks verbs - via `STEAM_COMPAT_DATA_PATH`, sets your newest GE-Proton as the default compat tool, and fetches official cover/hero/logo art.

```bash
# run each client once first so its prefix + .exe exist, then with Steam closed:
cod-steam-native          # add per-mode Plutonium + t7x/h1/h2 shortcuts
cod-steam-native list
cod-steam-native remove
```

Plutonium gets one shortcut per owned game+mode (Black Ops II Multiplayer, Zombies, World at War, ...) that launches straight into it via the `plutonium://play/<code>` protocol. The bubblewrap sandbox does not apply on this path (Steam runs the `.exe` directly) - use the standalone `cod-*` launchers when you want the sandbox.

## Store detection

`cod-t7x` and `cod-steamlink` locate your games from Steam's own metadata, so a game on any drive is found. They scan every Steam install layout - native (`~/.steam/steam`, `~/.local/share/Steam`), Flatpak (`~/.var/app/com.valvesoftware.Steam`), and Snap (`~/snap/steam`) - and read each one's `steamapps/libraryfolders.vdf` to follow **moved and additional library folders** to the app's `appmanifest_<id>.acf`. If detection ever misses, pass an explicit path (`t7x.blackOps3Dir`, or `cod-steamlink --dir`).

## Security

Every launcher runs inside a bubblewrap sandbox (`myModules.home.cod-clients.sandbox`, default on). Because these are closed-source binaries fetched from third-party CDNs, the sandbox exposes only what a game needs: your Steam library game files (read-only), the client's own prefix and state (read-write), `/nix/store`, and GPU/audio/input/display/network. It hides `$HOME` and every unrelated file, and nests inside umu's own Steam Runtime container. Set `COD_SANDBOX=0` in the environment to bypass it for a single launch (for debugging).

## Caveats

- **You must own the games** on Steam. These launchers mod games you own; they do not provide the base game.
- **t7x / BO3 is experimental on Linux**: upstream does not test Linux and there are reports of a GStreamer/Media-Foundation codec error under Proton with no confirmed fix. If you hit it, try `t7x.extraWinetricks = [ "mf" "mfplat" ]`.
- **The AlterWare family is experimental**: its Linux launch is unverified end-to-end and the iw4x/iw2 client exe names are inferred. Enable per-game, own the base game, and expect to verify (and possibly adjust) on first run.
- **Plutonium online play** needs a free Plutonium forum account and the latest revision (the client self-updates to it).
- **Horizon MW** builds a farm of your owned MWR install and runs the official launcher from it; the launcher self-updates and downloads mod files into the farm on first run. Needs `dotnet8` and `vcrun2022` in the prefix (handled automatically).
- **BOIII** is a community fork of the BOIII client. The DXVK rendering path is unverified on Linux; it may only work in dedicated-server mode under Wine. Report rendering issues to upstream.
- **CB Launcher** is a launcher hub, not a single-game client. It runs under Proton and can use existing Steam-installed games. Do not use it to download games you do not own.

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
myModules.home.cod-clients = {
  enable = true;
  plutonium.enable = true;
  t7x.enable = true;
};
```

After a rebuild the launcher commands (`cod-plutonium`, `cod-t7x`, `cod-steamlink`, `cod-steam-add`) are on your PATH and in your application menu.

## Running the clients

Run each launcher **from a terminal** the first time - you see the setup progress and any errors. The first launch of a client is slow and one-time: it downloads umu's Steam Runtime, builds the Wine prefix, and fetches the client; later launches are fast.

**`cod-plutonium`** - Black Ops 1/2, World at War (MW3/IW5 needs `plutonium.dotnet`):

```bash
cod-plutonium
```

First run fetches `plutonium.exe`, installs the prefix verbs (a few minutes), then opens Plutonium's launcher. In it: log in with your free Plutonium forum account, point it at your Steam game folder, pick a title, and play. Start with BO1/BO2/WaW - MW3/IW5 is best-effort (see Caveats).

**`cod-t7x`** - Black Ops III:

```bash
cod-t7x
```

Auto-detects your owned BO3 install, builds the symlink farm, fetches t7x, and launches it. Experimental on Linux; if you hit the codec error, set `t7x.extraWinetricks = [ "mf" "mfplat" ]` and rebuild.

For Steam integration - hours, launch options, per-shortcut Proton - see [Add to Steam](#add-to-steam-any-proton-launch-options) and [Steam hours-tracking](#steam-hours-tracking). To switch Proton for a single run without a rebuild, prefix the command:

```bash
COD_PROTON=~/.steam/steam/compatibilitytools.d/GE-Proton10-34 cod-plutonium
```

## Troubleshooting

- **First launch seems to hang** - it is downloading the umu runtime and building the prefix (Plutonium's verb install takes several minutes). Run from a terminal to watch; it happens once per client.
- **`no valid Proton ...`** - `protonPath` is not a directory containing a `proton` script. The default is fine; if you set it, point at a `.../GE-Proton*/` dir, use `protonPath = "steam"`, or `COD_PROTON=<path>`.
- **A client works only with `COD_SANDBOX=0`** - the sandbox is missing a bind the game needs; `COD_SANDBOX=0 cod-<client>` is the interim bypass. Please report it.
- **t7x: black screen or a "Media Feature Pack"/codec error** - the known GStreamer/Media-Foundation issue; try `t7x.extraWinetricks = [ "mf" "mfplat" ]`.
- **Game not found** - detection reads Steam's `libraryfolders.vdf`; for an unusual install pass `t7x.blackOps3Dir = "/path"` or `cod-steamlink --dir /path`. See Store detection.
- **Interrupted download** - fetches use `--remove-on-error`, so just re-run the launcher.

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
