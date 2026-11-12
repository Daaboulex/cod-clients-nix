# Compatibility

What each client needs, what is known to be rough, and what is behind the fixes
this repository ships. The Steam helpers are in [STEAM.md](STEAM.md).

## Clients

Every client is off until its `enable` option is set. You must own the games.
The launchers mod a copy you own and do not provide the base game.

| Command | Titles | Base game (own on Steam) | Notes |
|---|---|---|---|
| `cod-plutonium` | BO1, BO2, MW3, WaW | 202970 (BO2), 42700 (BO1), 10090 (WaW), 42750 (free MW3 route) | Standalone umu launcher. Point Plutonium at the Steam folder in its UI |
| `cod-t7x` | BO3 | 311210 (Black Ops III) | Standalone. Experimental on Linux |
| `cod-h1` | MWR | 393080 (Modern Warfare Remastered) | Aurora h1-mod. Farm plus self-updating client. Experimental |
| `cod-h2` | MW2CR | MW2 Campaign Remastered (Battle.net, not on Steam) | Aurora h2-mod. Set `h2.mw2crDir`. Experimental |
| `cod-iw5` | Modern Warfare 3 (2011) | 115300 | AlterWare. Experimental |
| `cod-iw6` | Ghosts | 209160 | AlterWare. Experimental |
| `cod-s1` | Advanced Warfare | 209650 | AlterWare. Experimental |
| `cod-iw2` | Call of Duty 2 | 2630 | AlterWare. Experimental |
| `cod-hmw` | MWR | 393080 | Horizon MW. Farm plus self-updating launcher. Experimental |
| `cod-boiii` | BO3 | 311210 | BOIII. Farm plus self-updating client. Experimental |
| `cod-cblauncher` | 17 CoD titles | - | CB Launcher hub. Experimental |

What each launcher does:

- `cod-plutonium` runs Black Ops 1 (T5), Black Ops 2 (T6), Modern Warfare 3
  (IW5) and World at War (T4). It fetches the official self-updating
  `plutonium.exe`, bootstraps a Proton prefix with the required winetricks
  verbs, and launches under umu-launcher.
- `cod-t7x` runs Black Ops III (T7). It fetches the official self-updating
  `t7x.exe` and runs it against a symlink farm of your owned retail Black Ops
  III install.
- `cod-h1` runs Modern Warfare Remastered through Aurora h1-mod. It fetches the
  self-updating `h1-mod.exe` and runs it against a symlink farm of your owned
  install.
- `cod-h2` runs MW2 Campaign Remastered through Aurora h2-mod. It runs the
  self-updating `h2-mod.exe` against a symlink farm of your owned install.
- `cod-iw5`, `cod-iw6`, `cod-s1` and `cod-iw2` are the AlterWare family: Modern
  Warfare 3 (2011), Ghosts, Advanced Warfare and Call of Duty 2. Each uses the
  native `alterware-launcher` to update the client into your owned Steam
  install, then launches it under umu.
- `cod-hmw` runs Horizon MW, a Modern Warfare Remastered mod. Its self-updating
  launcher downloads the mod into a symlink farm of your owned install.
- `cod-boiii` runs the BOIII client for Black Ops III. It is a drop-in
  self-updating client that runs against a symlink farm of your owned install.
- `cod-cblauncher` is the CB Launcher hub. It bundles about 17 community
  clients: Plutonium, BOIII, IW4x, CoD4x, IW6x, S1x, H1-Mod and H2-Mod, IW7-Mod,
  HorizonMW, Project BO4, and stock CoD1 and United Offensive. It downloads and
  launches those itself into a folder you grant through `cblauncher.gameDirs`.

## What is experimental

- t7x and Black Ops III. Upstream does not test Linux, and there are reports of
  a GStreamer or Media Foundation codec error under Proton with no confirmed
  fix. The remedies that exist are under
  [Black screen or a codec error](#t7x-or-boiii-shows-a-black-screen-or-a-codec-error).
- Modern Warfare 3 through Plutonium. It needs `plutonium.dotnet`, which is off
  by default because the install is slow and because MW3 has an unfixed
  no-cursor bug on NixOS with GE-Proton. Black Ops 1, Black Ops 2 and World at
  War do not need it.
- The AlterWare family. Its Linux launch is unverified end to end and the iw2
  client exe name is inferred. Enable per game, own the base game, and expect
  to verify, and possibly adjust, on the first run.
- Horizon MW. It builds a farm of your owned Modern Warfare Remastered install
  and runs the official launcher from it. The launcher updates itself and
  downloads mod files into the farm on the first run. It needs the .NET 8
  Desktop Runtime and VC++ 2022 in the prefix, which the `dotnetdesktop8` and
  `vcrun2022` winetricks verbs install automatically.
- BOIII. It is a community fork of the BOIII client. The DXVK rendering path is
  unverified on Linux, and it may only work in dedicated-server mode under
  Wine, where it does work. Report rendering issues to upstream.
- CB Launcher. It is a hub for many community clients, so it overlaps the
  individual `cod-*` clients and adds titles they do not cover: MW2 through
  IW4x, CoD4 through CoD4x, CoD1 and United Offensive, Infinite Warfare and
  Black Ops 4. It writes client and game files into the folder you point it at,
  so set `cblauncher.gameDirs` to a writable location and paste that path into
  its UI. Its Browse button is disabled under Wine, so you type the path. It
  deletes a game directory's `d3d11.dll` before launch, so do not point it at a
  retail Black Ops III that `cod-cleanops` has patched.
- Plutonium online play. It needs a free Plutonium forum account and the latest
  revision, which the client updates itself to.

## Game notes

Per-title behavior on Wayland desktops, from tested setups rather than
folklore. The launcher seeds CB Launcher's per-game launch options
(`cblauncher.launchOptions`), installs per-prefix winetricks, and applies
per-exe environment defaults. Anything listed as an in-game setting cannot be
packaged and is set once in the game's menu.

| Game | Packaged | In-game and notes |
|---|---|---|
| Advanced Warfare (s1x) | Rerouted prefix defaults to the Wayland recipe: `PROTON_USE_WAYLAND=1 PROTON_USE_SDL=1`. Pair it with a Proton that implements the Wayland toggle (proton-cachyos) | Display mode Borderless avoids the exclusive-fullscreen freeze class |
| Ghosts (iw6x) | `cblauncher.configFiles` enforces `r_displayMode "windowed (no border)"` on the primary monitor plus the menu-mouse routing and the frame cap in players2 configs | Borderless sidesteps the exclusive-fullscreen display switching behind the multi-monitor crash and alt-tab kill |
| CoD4 (iw3mp via CoD4X) | Rerouted prefix gets the frame cap. The shared runtime fixed the join-time crash class | `raw_input 1` and resolution = display resolution if the cursor sticks to an edge. Competitive fps points are 125, 250 and 333 |
| WaW, BO1, BO2 (Plutonium) | `raw_input "1"` seeded into the T5 and T6 player configs (the canonical Plutonium mouse fix). Frame cap through CB launch options, and as `DXVK_FRAME_RATE` on the standalone client (mouse speed is FPS-coupled) | BO1: `r_dof_enable 0` fixes the ADS blur. Keep fps caps at or under 165 there if mouse feel degrades |
| CoD2 | None by default | `PROTON_NO_ESYNC=1` is load-bearing if it black-screens after the menu |
| MW3 (iw5 via Plutonium) | None needed to launch | `vid_restart` in the console revives the menu mouse. Mouse Smoothing on and Vsync off correct the feel. Keep mouse polling at or under 500 Hz |
| Black Ops III (boiii) | Steam client sync is automatic. Through CB the packaged launch options default to `-nosteam` (Steam is an optional sidecar for BOIII, and without a reachable running Steam its client library fatally asserts) | Use Borderless Fullscreen. Exclusive fullscreen misbehaves on alt-tab |
| CoD1 and United Offensive (stock, via CB) | The CB prefix sets `PROTON_OLD_GL_STRING=1` (the curated Proton fix for the old-GL-extension-string crash class, inert for the D3D titles sharing the prefix) | - |
| CB Launcher dropdowns | Not fixable client-side | KWin XWayland popup handling (KDE bug 516450), unfixed upstream |

### Frame cap

The frame cap is the `maxFps` option. By default it is the highest declared
refresh rate of the host's displays, in whole Hz rounded down, minus 2. The
module reads those displays from the NixOS option
`myModules.desktop.displays.monitors`. On a host that does not declare it the
default is no cap, and `maxFps` can be set by hand.

The cap is injected wherever `com_maxfps` verifiably lands: launch options for
the arg-consuming CB games, default arguments for rerouted prefixes, and
Ghosts' config files. Black Ops III caps at 250 in its own menu and Black Ops 4
exposes no verified cap surface. Both stay manual settings.

### Raw input under XWayland

Raw-input starvation under XWayland (frozen or escaping cursors in this game
family) is fixed upstream by wine 11.13's focus-gated raw input. Proton builds
rebased on it retire the per-game workarounds above.

## Troubleshooting in full

### First launch seems to hang

It is downloading the umu runtime and building the prefix. Plutonium's verb
install takes several minutes. Run from a terminal to watch. It happens once
per client, and later launches are fast.

### no valid Proton

`protonPath` is not a directory containing a `proton` script. The default is
fine. If you set it, point at a `.../GE-Proton*/` directory, use
`protonPath = "steam"`, or `COD_PROTON=<path>`.

### A client works only with COD_SANDBOX=0

The sandbox is missing a bind the game needs. `COD_SANDBOX=0 cod-<client>` is
the interim bypass. Please report it.

### Steam must be installed, or BO3 says launching and then nothing happens

This affects BOIII, t7x and CB Launcher's BO3. The boiii-lineage clients gate
on the prefix's `HKLM\Software\Wow6432Node\Valve\Steam` `InstallPath` registry
value plus a `steam.exe` at that path. Their `steam_proxy` also loads
`steamclient64.dll` from there to build a Steam context, and a missing DLL
makes it hang after the gate passes.

The launcher syncs all of it into every prefix: the registry value, and
`steamclient.dll`, `steamclient64.dll`, `GameOverlayRenderer64.dll`,
`Steam.dll` and `steam.exe` copied from your installed Steam client's
`legacycompat/` directory, the same source and file set Proton uses. The
`steam.exe` is that directory's `SteamService.exe` under the name the clients
look for.

The copies are signature-tracked against the source files, so a Steam client
self-update re-syncs the prefix on the next launch instead of leaving stale
DLLs behind. This needs the Steam client installed. A Steam-less host prints a
clear message and only these clients are affected.

### BO3 via CB Launcher dies right after "Launching boiii.exe"

The sign is a Valve `pipes.cpp` "fatal stalled cross-thread pipe" assert. That
is Valve's steamclient library failing to reach a running, logged-in Steam
client. BOIII treats Steam as an optional sidecar: its server auth and CB's
presence and joins never use Steam. So the packaged default seeds `-nosteam`
into CB's BO3 launch options and the Valve library is never loaded.

You lose only the Steam overlay and live workshop sync. Set
`cblauncher.launchOptions.bo3 = ""` to restore the Steam integration attempt.

### A microphone icon flashes in the system tray at every launch (KDE Plasma)

That is Plasma's microphone-in-use privacy indicator
(`plasmashell_microphone`), not a launcher tray icon. Game audio engines and
CEF launchers open brief audio-capture probes while initializing, and Plasma
registers and removes the indicator for each short-lived stream. Capture itself
is legitimate, since in-game voice chat uses it. Measured: 45 registrations
during one CB Launcher start. It is desktop UX, not a launcher defect.

To stop the strobe, move the Microphone entry to the hidden area: System Tray
settings, then Entries, then Microphone, then Always hidden. Declaratively with
plasma-manager: `systemTray.items.hidden = [ "plasmashell_microphone" ]`. It
stays inspectable in the tray popup.

### CB Launcher dropdowns (language and others) do not appear

CEF `<select>` popups are separate native windows that Wine has historically
failed to paint (WineHQ bug 33943). The launcher forces software compositing
(`--disable-gpu --disable-gpu-compositing`, on top of `--in-process-gpu`), the
standard CEF-under-Wine cure, which costs nothing for a launcher UI.

If a dropdown still misbehaves, the popup usually exists but is unpainted.
Hover or sweep the mouse where the options would be, or use the arrow keys and
Enter.

### t7x or BOIII shows a black screen or a codec error

The codec error names the "Media Feature Pack". On GE-Proton 11 the video stack
is FFmpeg-based and the old `mf` and `mfplat` codec verbs are legacy. If intro
or menu videos still hang there, delete the game directory's `videos/` folder.
On older Protons `extraWinetricks = [ "mf" "mfplat" ]` for that client remains
the codec remedy, followed by a rebuild.

A black screen with audio on a host with many audio devices is a different
class. Add `[ "sound=alsa" ]` to that client's `extraWinetricks`, the same fix
Steam's protonfixes applies to retail BO3.

### Game not found

Detection reads Steam's `libraryfolders.vdf`. For an unusual install pass
`t7x.blackOps3Dir = "/path"` or `cod-steamlink --dir /path`. How detection
works is in [DESIGN.md](DESIGN.md).

### Interrupted download

Fetches use `--remove-on-error`, so just re-run the launcher.
