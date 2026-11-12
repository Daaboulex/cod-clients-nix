# Steam integration

Four optional helpers. Each is its own opt-in under
`programs.cod-clients`, off by default, so enable only the ones you use.
Each is a command you run yourself with Steam closed.

| Option | Command | Titles | Base game | What it does |
|---|---|---|---|---|
| `steamLink.enable` | `cod-steamlink` | BO2 (default) and any Plutonium title | as for `cod-plutonium` | Steam hours-tracking through a reversible exe swap |
| `steamAdd.enable` | `cod-steam-add` | all installed launchers | - | Adds each launcher to Steam as a non-Steam shortcut, with Proton and launch options per shortcut |
| `steamNative.enable` | `cod-steam-native` | the set-up clients | - | Adds each client's `.exe` as a shortcut under Steam's own Proton |
| `cleanops.enable` | `cod-cleanops` | BO3 retail multiplayer | 311210 (Black Ops III) | Drops the CleanOps `d3d11.dll` into owned BO3 (cheat removal and P2P). Launch through Steam |

## Steam hours-tracking: cod-steamlink

Plutonium runs on non-VAC servers and never touches the retail Steam client, so
launching it does not risk a VAC ban. By default it runs outside Steam, so
Steam does not count the time.

`cod-steamlink` wires it into Steam the way the community does it. It renames a
game's launch exe and drops `plutonium.exe` in its place, so Steam's Play opens
Plutonium and tracks the hours under that game. It does this safely and
reversibly.

```bash
cod-steamlink
cod-steamlink --appid N --exe NAME
cod-steamlink --dir /path/to/game
cod-steamlink --undo
```

With no argument it targets Black Ops II, app 202970, exe `t6mp.exe`. `--appid`
and `--exe` name a different title and exe. `--dir` gives the game directory
when detection misses it. `--undo` restores the original exe from its backup.

It resolves the game directory, backs up the original exe to `<exe>.cod-orig`,
copies in the fetched `plutonium.exe` and marks it read-only. Then it prints
the one command you run yourself to make the swap survive Steam auto-updates:

```bash
sudo chattr +i "<path>/t6mp.exe"
```

Because Plutonium's launcher lets you pick any title, one swap, for example
Black Ops II, is enough to track all your Plutonium hours under that game.

## Add to Steam: cod-steam-add

`cod-steam-add` registers every installed `cod-*` launcher as a non-Steam
shortcut. It is the "Add to Steam" that Heroic offers, done for you. Each
launcher then shows in Steam, tracks hours, and takes its own launch options
and Proton.

```bash
cod-steam-add
cod-steam-add list
cod-steam-add remove
```

With no argument it adds all installed launchers. `list` shows which are
registered and `remove` takes them out again.

Close Steam before adding or removing, because Steam rewrites `shortcuts.vdf`
on exit. The helper backs up that file, only ever touches its own tagged
entries, and never clobbers your other shortcuts. Restart Steam afterwards.

Each shortcut points at the launcher, so it keeps the bubblewrap sandbox, the
winetricks prefix and the runtime client fetch. That means Proton is chosen per
shortcut in Steam's Launch Options, not in the Compatibility dropdown. Steam's
forced Proton only drives a raw Windows `.exe` and would break a native
launcher script.

Set a specific Proton with `COD_PROTON=/path/to/proton %command%` in the
shortcut's Launch Options, or leave it to `protonPath`. Launch options and
Steam playtime work as normal.

## Steam-native shortcuts: cod-steam-native

`cod-steam-native` is the other side of that trade-off. Instead of the native
launcher, where the Compatibility dropdown cannot apply, it registers each
client's Windows `.exe`, so Steam runs it under its own Proton and the dropdown
works.

It reuses each client's already-prepared prefix through
`STEAM_COMPAT_DATA_PATH`, so Plutonium keeps its winetricks verbs. It sets the
compatibility tool of the new shortcuts to the highest-versioned Proton it
finds in Steam's `compatibilitytools.d`, and fetches official cover, hero and
logo art.

Run each client once first so its prefix and `.exe` exist. Then, with Steam
closed:

```bash
cod-steam-native
cod-steam-native list
cod-steam-native remove
```

With no argument it adds the shortcuts: one per mode for Plutonium, and one
each for t7x, BOIII, h1-mod, h2-mod and CB Launcher, for whichever of them are
set up.

Plutonium gets one shortcut per owned game and mode (Black Ops II Multiplayer,
Zombies, World at War and so on), each labeled with its own cover art and
Steam hours. Each passes `plutonium://play/<code>` as a best-effort direct
launch. Plutonium's launcher may still open for you to pick the title and mode.
The per-mode protocol launch is not confirmed to work under Proton, so verify
it on the first run.

The bubblewrap sandbox does not apply on this path, because Steam runs the
`.exe` directly. Use the standalone `cod-*` launchers when you want the
sandbox.

## CleanOps for retail Black Ops III: cod-cleanops

`cod-cleanops` drops the CleanOps `d3d11.dll` into your owned retail Black Ops
III, so launching BO3 through Steam loads CleanOps: cheat removal and P2P
hosting.

```bash
cod-cleanops
cod-cleanops --dir "/path/to/Call of Duty Black Ops III"
cod-cleanops --undo
```

Set the `WINEDLLOVERRIDES` launch option it prints in the game's Steam
properties. `--undo` reverses it.

CB Launcher deletes a game directory's `d3d11.dll` before launch, so do not
point CB Launcher at a Black Ops III that `cod-cleanops` has patched.
