# Architecture

How `cod-clients-nix` is built, how it runs, how to extend it, and the standards it follows.

## What this is

A single Home Manager module flake that packages community Call of Duty clients for Linux. Every client is ownership-respecting: it mods a game you own on Steam. The flake packages the reproducible launch environment (umu-launcher + Proton + a bubblewrap sandbox + a robust Steam-library resolver); the actual game clients are self-updating and fetched at runtime, never re-hosted or frozen into the Nix store.

It is a consumer of the Nix Packaging Standard (`github:Daaboulex/nix-packaging-standard`, pinned to a release tag), which supplies the CI, the lint/format gate, and the conformance checks.

## Repository layout

| Path | Role |
|---|---|
| `flake.nix` | Inputs, `overlays.default`, `homeManagerModules.default`, `packages.cod-*`, the `checks` |
| `hm-module.nix` | The `myModules.home.cod-clients` option surface + package wiring |
| `pkgs/cod-launcher/default.nix` | `mkCodLauncher` - the core launcher builder |
| `pkgs/cod-launcher/clients.nix` | Every client + the `mkFarmClient` / `mkAlterware` helpers |
| `pkgs/cod-launcher/sandbox.nix` | `cod_launch` - the bubblewrap wrapper |
| `pkgs/cod-launcher/steam-resolve.nix` | Steam-library resolver (native/Flatpak/Snap, moved libraries) |
| `pkgs/cod-launcher/steamlink.nix` | `cod-steamlink` - reversible exe-swap for Steam hours |
| `pkgs/cod-launcher/steam-add.{nix,py}` | `cod-steam-add` - native-launcher non-Steam shortcuts |
| `pkgs/cod-launcher/steam-native.{nix,py}` | `cod-steam-native` - `.exe` shortcuts under Steam's Proton |
| `pkgs/cod-launcher/cleanops.nix` | `cod-cleanops` - CleanOps DLL installer for retail BO3 |
| `pkgs/cod-launcher/*-test.py` | `runCommand` regression tests wired as flake checks |
| `.github/update.json` | Repo metadata (description, topics, `upstream.type`, arch drops) |
| `.github/workflows/*` | Synced byte-for-byte from the standard - do not hand-edit |
| `README.md` | User-facing docs (has the standard's `generated:*` markers) |

## The client model

Every client is one `writeShellApplication` (shellcheck-clean, `set -euo pipefail`) plus a `.desktop` entry, joined with `symlinkJoin`. There are three builders, all in `clients.nix`.

### `mkCodLauncher` (`default.nix`)

The base builder. Given a client spec it generates a launcher that, at run time:

1. Sources the Steam resolver and the sandbox function.
2. Creates the client's state dir at `~/.local/share/cod-clients/<name>`.
3. Resolves Proton (`resolve_proton`: `COD_PROTON` env, then `protonPath = "steam"` auto-detect, else the baked default) and validates it points at a directory containing a `proton` script.
4. On first run, installs the winetricks verbs into the umu prefix (marker-guarded, once).
5. Fetches the self-updating client `.exe` from its official CDN (`curl -fL --remove-on-error`) if absent.
6. Runs `acquire` / `preLaunch` hooks (per-client setup - farms, alterware-launcher, etc.).
7. Launches: `cod_launch umu-run "$run" <args>`.

Key parameters: `name`, `desktopName`, `url`, `exe`, `winetricks`, `env`, `extraArgs`, `acquire`, `preLaunch`, `protonPath`, `sandbox`.

### `mkFarmClient`

For fetch-and-farm clients (t7x, h1, h2). It fetches a self-updating `.exe`, builds a symlink-farm of the owned game (so the retail install is never modified), optionally real-copies a hash-checked exe, and launches the client from the farm. Adding one is a one-liner:

```nix
h1 = mkFarmClient {
  name = "h1";
  desktopName = "Call of Duty: Modern Warfare Remastered (h1-mod)";
  gameName = "Modern Warfare Remastered";
  appid = "393080";
  url = "https://github.com/auroramod/h1-mod/releases/latest/download/h1-mod.exe";
  exe = "h1-mod.exe";
  dirOverride = mwrDir;
};
```

`realCopyExe` (optional) names an exe that must be a real copy in the farm, not a symlink (t7x hash-checks `BlackOps3.exe`).

### `mkAlterware`

For the AlterWare family (iw5/iw6/s1/iw2). It runs the native `alterware-launcher` (from nixpkgs) to update the client into the owned Steam game dir, then launches `<gamedir>/<code>.exe` under umu. Spec: `name`, `desktopName`, `code`, `appid`, `exe`, `modes`.

### Client roster

| Command | Game | Builder |
|---|---|---|
| `cod-plutonium` | BO1/BO2/WaW (MW3 opt-in) | `mkCodLauncher` + winetricks verbs |
| `cod-t7x` | BO3 | `mkFarmClient` (real-copies `BlackOps3.exe`) |
| `cod-h1` | Modern Warfare Remastered | `mkFarmClient` |
| `cod-h2` | MW2 Campaign Remastered | `mkFarmClient` |
| `cod-iw5`/`iw6`/`s1`/`iw2` | MW3-2011/Ghosts/AW/CoD2 | `mkAlterware` |

## Runtime: umu + Proton + sandbox

`umu-launcher` runs the Windows `.exe` under Proton, bringing its own Steam Linux Runtime (no Steam needed). The default Proton is the pinned nixpkgs `proton-ge-bin.steamcompattool` (its `out` is a 112-byte stub - always use `.steamcompattool`).

Every launch is wrapped in an outer bubblewrap (`cod_launch` in `sandbox.nix`): it exposes `/nix/store` (ro), the Steam-library `steamapps` (ro), the client's own state/prefix (rw), GPU/audio/input/display sockets, the D-Bus session bus, and the network - and hides `$HOME` and everything else. `COD_SANDBOX=0` bypasses it for one launch. The verb install runs unsandboxed (`COD_SANDBOX=0`).

The Steam resolver (`steam-resolve.nix`) provides `_steam_roots` (native/Flatpak/Snap base dirs), `resolve_steam_dir <appid>` (follows moved/extra libraries via `libraryfolders.vdf` to the install dir), and `list_steam_libraries`.

## Proton selection (three ways)

- Pinned nixpkgs GE-Proton (default, reproducible).
- `protonPath = "steam"` - auto-detect the newest Proton in your Steam `compatibilitytools.d`.
- `COD_PROTON=<path> cod-<client>` - override per launch.

## The Home Manager module

`hm-module.nix` exposes `myModules.home.cod-clients`:

- `enable`, `sandbox` (default on), `protonPath`.
- `plutonium.{enable, dotnet, extraWinetricks, extraArgs}`.
- `t7x.{enable, blackOps3Dir, extraWinetricks, extraArgs}`.
- `h1.{enable, mwrDir, extraArgs}`, `h2.{enable, mw2crDir, extraArgs}`.
- `alterware.{iw5,iw6,s1,iw2}.enable` (default-off, experimental).

`config` instantiates the clients (passing the option values into `clients.nix`) and adds the enabled launchers plus the three helpers (`cod-steamlink`, `cod-steam-add`, `cod-steam-native`, `cod-cleanops`) to `home.packages`.

## Steam integration

Four independent tools, each fail-closed (refuse while Steam runs, back up before writing, only touch their own tagged entries, reversible):

- `cod-steamlink` - swaps a game's exe for `plutonium.exe` so Steam's Play tracks hours; prints the `sudo chattr +i` line; `--undo`.
- `cod-cleanops` - drops the CleanOps `d3d11.dll` into owned BO3; prints the `WINEDLLOVERRIDES` launch option; `--undo`.
- `cod-steam-add` - registers each installed launcher as a non-Steam shortcut pointing at the native `cod-*` script. Keeps the sandbox; Proton is chosen via `COD_PROTON=... %command%` in Launch Options (the Compatibility dropdown cannot drive a native script).
- `cod-steam-native` - registers shortcuts pointing at the client's Windows `.exe`, so Steam runs it under its own Proton and the Compatibility dropdown works. Reuses each client's prepared umu prefix via `STEAM_COMPAT_DATA_PATH`, sets GE-Proton in `config.vdf` CompatToolMapping, fetches cover art by appid, and gives Plutonium one shortcut per owned game+mode via `plutonium://play/<code>`. No sandbox on this path.

The two shortcut tools share the same Python pattern: binary `shortcuts.vdf` is loaded/merged/dumped via `python3Packages.vdf`, entries are tagged `cod-clients-nix`, matched by app name (rebuild-safe), and deduped by real path across symlinked Steam roots. `cod-steam-native` additionally edits the text `config.vdf` and fetches art. Both have a `runCommand` unit test that round-trips through real `vdf`.

## Flake outputs and the standard

`flake.nix` imports `inputs.std.flakeModules.base`, which provides the git-hooks gate (nixfmt-rfc-style, typos, rumdl, check-readme-sections), the formatter, the dev shell, `std-conformance`/`std-devstate`/`std-update-json`, and aliases every declared package into `checks` on the systems its `meta.platforms` supports. The flake declares:

- `packages.cod-*` (one per client + helper) and `packages.default`.
- `overlays.default` exposing every `cod-*` (the standard's shape is package + overlay + module).
- `homeManagerModules.default`.
- `checks.module-eval-hm` (full HM module eval with clients enabled), `checks.steam-add-logic`, `checks.steam-native-logic`.

Conformance: MIT `LICENSE` (the packaging is MIT; clients are `meta.license = unfree`), `.github/update.json` with `upstream.type: "none"` (third-party wrapper, no CHANGELOG required), a `platforms.aarch64-linux` drop reason, and the synced workflow/`.envrc`/`.gitignore` files kept byte-identical (enforced by `std-conformance`). Never hand-edit the synced files - change them in the standard and re-sync.

## CI/CD

`ci.yml` (identical fleet-wide, SHA-pinned actions): on push/PR it reclaims disk, then on a `[ubuntu-latest, ubuntu-24.04-arm]` matrix builds every output the flake declares for that system via `nix-fast-build --skip-cached`. `cache.nixos.org` substitutes unmodified deps (GE-Proton included). It retries transient fetch failures once. A separate `no-ai-files` job guards the tree.

Why it is robust: the launchers are `writeShellApplication` packages with no build-time network - the client downloads happen at launch, not in CI, so a failed `curl` can never break the build. Every runtime fetch uses `--remove-on-error`; every Steam helper backs up before writing. `maintenance.yml` refreshes `flake.lock` weekly and opens an issue if the rebuild goes red.

## Adding a client

1. Pick the builder: `mkFarmClient` (a self-updating `.exe` + owned game), `mkAlterware` (an alterware-launcher code), or `mkCodLauncher` directly (needs winetricks verbs, like Plutonium).
2. Add the block to `clients.nix` (for a farm client it is the one-liner above) and, if it takes options, thread `dirOverride`/`extraArgs` through the function params.
3. Add the option to `hm-module.nix` (`enable`, a `<game>Dir`, `extraArgs`), pass the values into the `clients` call, and add `++ lib.optional cfg.<name>.enable clients.<name>` to `home.packages`.
4. Add `cod-<name> = clients.<name>;` to `overlays.default` and `packages.cod-<name> = pkgs.cod-<name>;` in `flake.nix`, and `<name>.enable = true;` to the `module-eval-hm` config.
5. Document it in `README.md` (intro bullet + clients table).
6. `git add` the new files, `nix flake check`, commit, push.

If it is a Steam-launched-only client (like CleanOps), model it as a helper (drop a file into the owned game + print the launch option) rather than a `mkCodLauncher` launcher.

## Working on the repo

- `nix flake check` is the gate (builds every package, runs conformance + the module eval + the logic tests). Builds offload to the build farm when reachable, else build locally.
- Flakes see only git-tracked files: `git add` new files before `nix flake check`, or eval fails with "not tracked by Git".
- `nix fmt` currently errors in this repo (a treefmt/nixfmt stdin quirk). Format a flagged file directly with `nix run nixpkgs#nixfmt-rfc-style -- <file>`; the pre-commit hook is the real gate.
- Do not revert the treefmt hook with `git checkout`; re-run the formatter.

## Standards to follow

- Ownership line: only package clients that mod a game you own. Never package a tool whose function is bypassing ownership verification or distributing/downloading the base games.
- Fail closed: validate the game dir, back up before overwriting, `--remove-on-error` on fetches, refuse Steam-config writes while Steam runs, everything reversible.
- No comments in source (names/types/structure carry intent); ASCII only.
- Commit as Daaboulex, no AI attribution; run the full check and commit only on green; end substantive commits with an `Eval:` trailer (`nix-flake-check=pass`).
- Runtime-update model: fetch the official self-updating client at launch; never re-host or freeze a game payload.
