# Design

Why the launchers are built the way they are. How the code is laid out, and how
to add a client, is in [ARCHITECTURE.md](../ARCHITECTURE.md).

## Where the clients come from

This is a Nix flake that launches community Call of Duty clients on Linux
without a hand-rolled Wine prefix. It packages the launchers, not the clients.

| | |
|---|---|
| Project | Plutonium (plutonium.pw) and t7x (alterware.dev), fetched at runtime, self-updating |
| License | Proprietary, third-party clients. The packaging is MIT, see [LICENSE](../LICENSE) |
| Tracked | None. The official clients update themselves at runtime |

The live client binaries are fetched at runtime into a per-client state
directory, `~/.local/share/cod-clients/<name>`, and maintain themselves from
their own official servers. The flake never pins, re-hosts or freezes a game
payload. You bring the games: each client mods a copy you legitimately own on
Steam.

Each launcher downloads from one place:

| Launcher | Fetched from |
|---|---|
| `cod-plutonium` | `https://cdn.plutonium.pw/updater/plutonium.exe` |
| `cod-t7x` | `https://master.bo3.eu/t7x/t7x.exe` |
| `cod-h1` | `https://github.com/auroramod/h1-mod/releases/latest/download/h1-mod.exe` |
| `cod-h2` | `https://h2-mod.alicent.cat/data/h2-mod.exe` |
| `cod-hmw` | `https://ghost.cdn.horizonmw.org/launcher/HMW_Launcher.zip` |
| `cod-boiii` | `https://github.com/Ezz-lol/boiii-free/releases/latest/download/boiii.exe` |
| `cod-cblauncher` | `https://github.com/CBServers/updater/raw/main/updater/cb-launcher/cb-launcher.exe` |
| `cod-iw5`, `cod-iw6`, `cod-s1`, `cod-iw2` | through the `alterware-launcher` package from nixpkgs |
| `cod-cleanops` | `https://raw.githubusercontent.com/notnightwolf/cleanopsT7/main/d3d11.dll` |

## The sandbox

Every launcher runs inside a bubblewrap sandbox. The option is
`programs.cod-clients.sandbox`, on by default. The reason is that these
are closed-source binaries fetched from third-party CDNs.

The sandbox exposes what a game needs:

- your Steam library game files, read-only
- the client's own prefix and state, read-write
- `/nix/store`
- GPU, audio, input and display
- the D-Bus session bus and the network

Some clients get more. An AlterWare client gets its game directory read-write.
CB Launcher gets the directories named in `cblauncher.gameDirs` read-write. A
game rerouted by `cblauncher.subProton` gets its `gameDir` and `extraGameDirs`
read-write.

Each Steam library's `steamapps/shadercache` is overlaid with a writable
per-client directory. The Steam client library and mesa write their
appid-scoped shader cache there instead of failing on the read-only library,
and never touch your real Steam state.

It hides `$HOME` and every unrelated file, and umu's own Steam Runtime
container runs inside it. Set `COD_SANDBOX=0` in the environment to bypass it
for a single launch, for debugging.

Two things run outside it. The one-time prefix setup, which is the winetricks
verbs and the registry writes, runs unsandboxed. So does a shortcut made by
`cod-steam-native`, because Steam starts that `.exe` itself.

## Choosing Proton

`protonPath` is what umu runs the clients under. The default pins the nixpkgs
GE-Proton reproducibly, through its `steamcompattool` output. Set it to
`"steam"` to auto-detect the newest Proton in your Steam `compatibilitytools.d`,
which is where ProtonPlus installs its builds, or to a specific Proton path.

The auto-detect skips an aarch64 Proton build on an x86_64 host, so a wrongly
downloaded arm64 GE-Proton cannot be picked.

Three runtime overrides need no rebuild, in priority order:

1. `COD_PROTON=<path>` for a single launch.
2. A per-client file `~/.config/cod-clients/<name>.proton`, for example
   `cblauncher.proton`, to pin one client's Proton.
3. The global file `~/.config/cod-clients/proton`.

Each file holds a Proton path or a `compatibilitytools.d` tool name, and
applies to application menu launches too. To switch Proton for a single run:

```bash
COD_PROTON=~/.steam/steam/compatibilitytools.d/GE-Proton10-34 cod-plutonium
```

### The cod-proton picker

`cod-proton` is the friendly picker for those override files. It is installed
only when `protonPath = "steam"`, the route where you have several Protons to
choose between. On the default pinned route Proton is fixed, so there is
nothing to pick and no picker is added.

- `cod-proton cblauncher` opens a menu of your installed Protons and writes the
  right file for you. The menu is a KDE or GNOME dialog if one is available,
  otherwise a numbered terminal list.
- `cod-proton cblauncher auto` clears that override.
- `cod-proton` alone lists your Protons and the current overrides.

On the default route Proton is switched instead through Steam's Compatibility
dropdown with `steamNative`, or by writing an override file by hand.

## Finding the games

`cod-t7x` and `cod-steamlink` locate your games from Steam's own metadata, so a
game on any drive is found. They scan every Steam install layout:

- native: `~/.steam/steam` and `~/.local/share/Steam`
- Flatpak: `~/.var/app/com.valvesoftware.Steam`
- Snap: `~/snap/steam`

They read each one's `steamapps/libraryfolders.vdf` to follow moved and
additional library folders to the app's `appmanifest_<id>.acf`. If detection
ever misses, pass an explicit path: `t7x.blackOps3Dir`, or
`cod-steamlink --dir`. An empty `t7x.blackOps3Dir` means auto-detect Black Ops
III, app 311210.

## Application menu entries

`desktopEntries` controls the application menu (`.desktop`) entry per client. A
client absent from the set is shown. Set it to `false`, for example
`desktopEntries.boiii = false`, to install the launcher without a menu entry,
for Steam-only or command-line use.

## Options

Every option under `programs.cod-clients` is declared, with its type,
default and description, in [hm-module.nix](../hm-module.nix). The flake exports
the module as `homeModules.default`.
