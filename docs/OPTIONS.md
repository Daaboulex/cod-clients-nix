# Options

Every option the modules of this flake declare. This file is generated from the module sources: change a description there, then run `nix run .#std-write-option-reference`.

## Home Manager module

Declared in [hm-module.nix](../hm-module.nix).

### `myModules.home.cod-clients.enable`

Whether to enable the community Call of Duty client launchers (umu + Proton + bubblewrap).

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.alterware.iw2.enable`

Whether to enable the iw2-mod launcher (Call of Duty 2) -- experimental.

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.alterware.iw2.env`

Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = "1".

Type: `attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.alterware.iw2.extraArgs`

Extra arguments passed to iw2-mod.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.alterware.iw2.extraWinetricks`

Winetricks verbs installed into this client's own prefix.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.alterware.iw2.gameDir`

Path to an existing Call of Duty 2 install directory (any source, e.g. a CB
Launcher download dir). Empty = auto-detect from Steam's
libraryfolders.vdf (app 2630). The alterware-launcher lays its
client files into this directory on each run.

Type: `string`. Default: `""`.

### `myModules.home.cod-clients.alterware.iw5.enable`

Whether to enable the iw5-mod launcher (Modern Warfare 3 (2011)) -- experimental.

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.alterware.iw5.env`

Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = "1".

Type: `attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.alterware.iw5.extraArgs`

Extra arguments passed to iw5-mod.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.alterware.iw5.extraWinetricks`

Winetricks verbs installed into this client's own prefix.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.alterware.iw5.gameDir`

Path to an existing Modern Warfare 3 (2011) install directory (any source, e.g. a CB
Launcher download dir). Empty = auto-detect from Steam's
libraryfolders.vdf (app 115300). The alterware-launcher lays its
client files into this directory on each run.

Type: `string`. Default: `""`.

### `myModules.home.cod-clients.alterware.iw6.enable`

Whether to enable the iw6-mod launcher (Ghosts) -- experimental.

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.alterware.iw6.env`

Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = "1".

Type: `attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.alterware.iw6.extraArgs`

Extra arguments passed to iw6-mod.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.alterware.iw6.extraWinetricks`

Winetricks verbs installed into this client's own prefix.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.alterware.iw6.gameDir`

Path to an existing Ghosts install directory (any source, e.g. a CB
Launcher download dir). Empty = auto-detect from Steam's
libraryfolders.vdf (app 209160). The alterware-launcher lays its
client files into this directory on each run.

Type: `string`. Default: `""`.

### `myModules.home.cod-clients.alterware.s1.enable`

Whether to enable the s1-mod launcher (Advanced Warfare) -- experimental.

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.alterware.s1.env`

Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = "1".

Type: `attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.alterware.s1.extraArgs`

Extra arguments passed to s1-mod.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.alterware.s1.extraWinetricks`

Winetricks verbs installed into this client's own prefix.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.alterware.s1.gameDir`

Path to an existing Advanced Warfare install directory (any source, e.g. a CB
Launcher download dir). Empty = auto-detect from Steam's
libraryfolders.vdf (app 209650). The alterware-launcher lays its
client files into this directory on each run.

Type: `string`. Default: `""`.

### `myModules.home.cod-clients.boiii.enable`

Whether to enable the BOIII client (Black Ops III) -- experimental, default-off.

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.boiii.blackOps3Dir`

Path to the owned Black Ops III Steam install directory. Empty =
auto-detect from Steam's libraryfolders.vdf (app 311210).

Type: `string`. Default: `""`.

### `myModules.home.cod-clients.boiii.env`

Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = "1".

Type: `attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.boiii.extraArgs`

Extra arguments passed to boiii.exe.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.boiii.extraWinetricks`

Extra winetricks verbs for the BOIII prefix. Same levers as t7x:
mf/mfplat is a legacy codec remedy on GE-Proton 11 (delete the game's
videos directory instead if videos hang), and [ "sound=alsa" ] cures
the black-screen-with-audio class on hosts with many audio devices.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.cblauncher.enable`

Whether to enable the CB Launcher for community CoD clients -- experimental, default-off.

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.cblauncher.configFiles`

Declarative seta enforcement in game config files, keyed by a path
relative to each cblauncher.gameDirs root -> dvar -> value. Before
every launch each existing root has matching files upserted: a
present seta line is rewritten to the declared value, a missing one
is appended, so whatever a game saves on exit is reasserted next
start. The default forces Ghosts into borderless on the primary
monitor, which sidesteps its exclusive-fullscreen display switching
(the multi-monitor crash and alt-tab kill class) and keeps its menu
mouse routed and its frame cap applied.

Type: `attribute set of attribute set of string`. Default: `Ghosts borderless-on-primary display settings plus com_maxfps`.

Example:

```nix
{
  "cod4_game_files/main/autoexec_mp.cfg" = {
    raw_input = "1";
  };
}
```

### `myModules.home.cod-clients.cblauncher.env`

Environment for the CB Launcher Proton session and every game it starts
in its prefix, e.g. PROTON_ENABLE_WAYLAND = "1".

Type: `attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.cblauncher.extraArgs`

Extra arguments passed to cb-launcher.exe, appended after the packaged
-portable and --in-process-gpu flags.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.cblauncher.extraWinetricks`

Extra winetricks verbs for the CB Launcher prefix, added on top of its base set.
Use this for a sub-client's own dependency (e.g. dotnet472 for its Plutonium MW3,
or mf/mfplat for its BOIII codec path) -- the whole CB prefix is shared, so a verb
added here is available to every game it manages.

Type: `list of string`. Default: `[ ]`.

Example:

```nix
[
  "dotnet472"
  "mf"
  "mfplat"
]
```

### `myModules.home.cod-clients.cblauncher.gameDirs`

Directories CB Launcher may download, patch, and manage games in, each bound
read-write in its sandbox. Default empty = fail closed (only its own state is
writable, so its game download/patch paths cannot run). List a writable
fresh-download folder and/or existing game install dirs; then paste the matching
path into CB Launcher's UI (its Browse button is disabled under Wine, so you type
the path). The launcher creates any missing listed directory on start.

Type: `list of string`. Default: `[ ]`.

Example:

```nix
[
  "/home/you/Games/cod"
]
```

### `myModules.home.cod-clients.cblauncher.gameSettings`

Per-game settings inside the shared CB Launcher prefix, keyed by the
executable name as Wine sees it. Wine scopes AppDefaults registry
entries and DXVK scopes config-file sections per executable, so each
game CB launches can carry its own Windows version, DLL overrides,
mouse capture, and DXVK options. The Proton build, the ntsync/esync
class, and the sandbox shape stay launcher-wide (one process tree).

Type: `attribute set of (submodule)`. Default: `{ }`.

Example:

```nix
{
  "iw5mp.exe" = {
    registry."" .Version = "win7";
    registry."X11 Driver".GrabFullscreen = "Y";
    dxvk = "d3d9.maxFrameRate = 240";
  };
}
```

### `myModules.home.cod-clients.cblauncher.gameSettings.<name>.dxvk`

dxvk.conf options for this executable's config section.

Type: `strings concatenated with "\n"`. Default: `""`.

### `myModules.home.cod-clients.cblauncher.gameSettings.<name>.registry`

String values written under HKCU\Software\Wine\AppDefaults\<exe>\<subkey>,
keyed subkey -> value name -> data. The "" subkey is the exe's root key
(e.g. Version = "win7"); other Wine keys scope the same way (DllOverrides,
"X11 Driver"). Applied via regedit when the settings change; exes removed
from this option get their AppDefaults key deleted.

Type: `attribute set of attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.cblauncher.launchOptions`

Per-game launch options seeded into CB Launcher's properties.json
(<game>-launch-options keys) before each start -- the launcher UI has
no field for them under Wine. CB appends them to the game's command
line. The ghosts default routes mouse input past the raw-input path
that XWayland starves on Wayland desktops, which makes the menu
usable. The bo3 default is "-nosteam": BOIII's Steam integration is
an optional sidecar (its auth and CB's presence/joins are
Steam-free), and without a reachable running Steam client the Valve
steamclient library it would load can kill the game with a fatal
"stalled cross-thread pipe" assert; bypassing it costs only the
Steam overlay and live workshop sync. Set a game's key to "" to
seed nothing for it (bo3 = "" restores the Steam integration
attempt).

Type: `attribute set of string`. Default: `per-game +set com_maxfps maxFps for the arg-consuming clients, plus bo3 = "-nosteam"`.

Example:

```nix
{
  iw5 = "+vid_restart";
}
```

### `myModules.home.cod-clients.cblauncher.subProton`

Per-game Proton for games CB Launcher starts, keyed by the exe name CB
spawns. cb-launcher runs every game as a plain child in its own prefix
(one Proton), so the launcher itself cannot vary Proton per game; this
option reroutes instead: the moment CB spawns a listed exe in the CB
prefix, that process is stopped (before the game initializes) and the
same exe is relaunched from the same CB-managed gameDir in its own
prefix under the given Proton, with the arguments CB passed (captured
from the spawned command line; whitespace-split). CB's UI shows the
game as exited and its own presence/stop controls do not track the
rerouted process; closing CB does not close the game. Exes not listed
launch unchanged inside the CB prefix.

Type: `attribute set of (submodule)`. Default: `{ }`.

Example:

```nix
{
  "s1x.exe" = {
    protonPath = "${pkgs.proton-ge.v10.steamcompattool}";
    gameDir = "/home/user/Games/CoD/aw_game_files";
  };
}
```

### `myModules.home.cod-clients.cblauncher.subProton.<name>.env`

Environment for this game's Proton session, e.g. PROTON_NO_NTSYNC = "1".

Type: `attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.cblauncher.subProton.<name>.extraArgs`

Arguments always passed to the game, before the ones CB supplied.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.cblauncher.subProton.<name>.extraGameDirs`

Additional CB-managed game directories this exe must see (absolute
paths), bound read-write into its sandbox -- e.g. the WaW/BO1/BO2
directories for plutonium.exe, which serves several titles.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.cblauncher.subProton.<name>.extraWinetricks`

Extra winetricks verbs added to this game's own prefix, on top of its CB base verb set.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.cblauncher.subProton.<name>.gameDir`

The CB-managed directory holding this game and its client exe (absolute path); null derives <first gameDirs root>/<game>_game_files for the known exes.

Type: `null or string`. Default: `null`.

### `myModules.home.cod-clients.cblauncher.subProton.<name>.protonPath`

Proton directory this game runs under, e.g. "${pkgs.proton-ge.v10.steamcompattool}"; null inherits the global protonPath.

Type: `null or string`. Default: `null`.

### `myModules.home.cod-clients.cleanops.enable`

Whether to enable the cod-cleanops helper (drops the CleanOps d3d11.dll into retail Black Ops III for Steam-launched multiplayer).

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.desktopEntries`

Per-client app-drawer control, keyed by client name (plutonium, t7x, h1, h2,
hmw, boiii, cblauncher, iw5, iw6, s1, iw2). A client absent from this set gets a
.desktop entry (shown in the app drawer); set it to false to install the launcher
without a drawer entry, for Steam-only or CLI-only use.

Type: `attribute set of boolean`. Default: `{ }`.

Example:

```nix
{
  boiii = false;
}
```

### `myModules.home.cod-clients.h1.enable`

Whether to enable the h1-mod launcher (Modern Warfare Remastered, Aurora) -- experimental.

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.h1.env`

Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = "1".

Type: `attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.h1.extraArgs`

Extra arguments passed to h1-mod.exe.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.h1.extraWinetricks`

Extra winetricks verbs added to the h1-mod prefix.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.h1.mwrDir`

Path to the owned Modern Warfare Remastered Steam install directory. Empty =
auto-detect from Steam's libraryfolders.vdf (app 393080).

Type: `string`. Default: `""`.

### `myModules.home.cod-clients.h2.enable`

Whether to enable the h2-mod launcher (Modern Warfare 2 Campaign Remastered, Aurora) -- experimental.

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.h2.env`

Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = "1".

Type: `attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.h2.extraArgs`

Extra arguments passed to h2-mod.exe.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.h2.extraWinetricks`

Extra winetricks verbs added to the h2-mod prefix.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.h2.mw2crDir`

Path to the owned Modern Warfare 2 Campaign Remastered install directory.
MW2CR is not sold on Steam (PC release is Battle.net-only), so it cannot be
auto-detected -- set this explicitly to your installed game directory.

Type: `string`. Default: `""`.

### `myModules.home.cod-clients.hmw.enable`

Whether to enable the Horizon MW launcher (Modern Warfare Remastered mod) -- experimental, default-off.

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.hmw.env`

Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = "1".

Type: `attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.hmw.extraArgs`

Extra arguments passed to Horizon MW Launcher.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.hmw.extraWinetricks`

Extra winetricks verbs added to the Horizon MW prefix.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.hmw.mwrDir`

Path to the owned Modern Warfare Remastered Steam install directory. Empty =
auto-detect from Steam's libraryfolders.vdf (app 393080).

Type: `string`. Default: `""`.

### `myModules.home.cod-clients.maxFps`

Frame cap injected into every client that verifiably consumes
com_maxfps: the CB-managed arg-consuming games via launchOptions, the
rerouted prefixes via their default arguments, and Ghosts via its
config files. The standalone Plutonium client carries the same cap as
a DXVK frame limit (DXVK_FRAME_RATE) because the old engines couple
mouse speed to frame rate. Derived from the host displays module so a
240 Hz panel yields 237 and the cap stays inside the adaptive-sync
window; null disables injection. Black Ops III caps at 250 in its own
menu and Black Ops 4 carries no verified cap surface -- both stay
manual.

Type: `null or signed integer`. Default: `highest declared monitor refresh minus 2, null without a displays module`.

### `myModules.home.cod-clients.plutonium.enable`

Whether to enable the Plutonium client launcher (Black Ops 1/2, MW3, WaW).

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.plutonium.dotnet`

Whether to enable MW3/IW5 support in the Plutonium prefix (installs dotnet472). Slower first-run,
and MW3/IW5 has an unfixed no-cursor bug on NixOS + GE-Proton.

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.plutonium.env`

Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = "1".

Type: `attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.plutonium.extraArgs`

Extra arguments passed to plutonium.exe (advanced/LAN use).

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.plutonium.extraWinetricks`

Extra winetricks verbs added to the Plutonium prefix.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.protonPath`

Proton the clients run under (a directory containing the `proton` script). The
default pins nixpkgs GE-Proton reproducibly. Set it to the string "steam" to
auto-detect the newest Proton in your Steam compatibilitytools.d (where ProtonPlus
installs its builds; an aarch64 build is skipped on x86_64), or to a specific
Proton path. Three runtime overrides need no rebuild, highest first:
COD_PROTON=<path> for a single launch; the per-client file
$XDG_CONFIG_HOME/cod-clients/<name>.proton; the global
$XDG_CONFIG_HOME/cod-clients/proton. Each file holds a Proton path or a
compatibilitytools.d tool name and applies to app-drawer launches too; the
cod-proton picker (installed when this is "steam") writes them for you.

Type: `string`. Default: `"${pkgs.proton-ge-bin.steamcompattool}"`.

### `myModules.home.cod-clients.protonPaths`

Per-client Proton overrides, keyed by client name (plutonium, t7x, h1, h2,
hmw, boiii, cblauncher, iw5, iw6, s1, iw2). A client absent from this set uses
the global `protonPath`. Each standalone client is its own umu session and
prefix, so different clients can run different wine majors from one config.
CB Launcher is one process tree: every game it spawns is a plain child
process inheriting the cblauncher entry, so a per-game Proton through CB
does not exist.

Type: `attribute set of string`. Default: `{ }`.

Example:

```nix
{
  s1 = "${pkgs.proton-ge.v10.steamcompattool}";
  iw6 = "${pkgs.proton-ge.v10.steamcompattool}";
}
```

### `myModules.home.cod-clients.sandbox`

Run every client inside a bubblewrap sandbox that exposes only game files
(Steam libraries, read-only), the client's own prefix/state (read-write),
and GPU/audio/input/display/network -- no $HOME or unrelated files. Each
Steam library's steamapps/shadercache is overlaid with a writable
per-client directory, so the Steam client library and mesa can write the
appid-scoped shader cache they expect without touching the real library.
Set the COD_SANDBOX=0 environment variable at runtime to bypass the
sandbox for one launch.

Type: `boolean`. Default: `true`.

### `myModules.home.cod-clients.steamAdd.enable`

Whether to enable the cod-steam-add helper (registers installed clients as non-Steam shortcuts running the sandboxed native launcher; Proton via per-shortcut launch options).

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.steamLink.enable`

Whether to enable the cod-steamlink helper (reversible exe-swap so a Steam game's Play button launches Plutonium and tracks hours).

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.steamNative.enable`

Whether to enable the cod-steam-native helper (registers each client's Windows .exe as a Steam shortcut under Steam's own Proton, so the Compatibility dropdown works; per-mode Plutonium + cover art).

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.t7x.enable`

Whether to enable the t7x client launcher (Black Ops III) -- experimental on Linux.

Type: `boolean`. Default: `false`.

### `myModules.home.cod-clients.t7x.blackOps3Dir`

Path to the owned retail Black Ops III Steam install directory. Empty =
auto-detect from Steam's libraryfolders.vdf (app 311210).

Type: `string`. Default: `""`.

### `myModules.home.cod-clients.t7x.env`

Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = "1".

Type: `attribute set of string`. Default: `{ }`.

### `myModules.home.cod-clients.t7x.extraArgs`

Extra arguments passed to t7x.exe.

Type: `list of string`. Default: `[ ]`.

### `myModules.home.cod-clients.t7x.extraWinetricks`

Extra winetricks verbs for the t7x prefix. The old media-foundation
codec remedy ([ "mf" "mfplat" ]) is legacy on GE-Proton 11's FFmpeg
video stack -- if intro videos still hang there, deleting the game's
videos directory is the current workaround. Another known BO3 lever:
[ "sound=alsa" ] if the game black-screens with audio on a host with
many audio devices.

Type: `list of string`. Default: `[ ]`.
