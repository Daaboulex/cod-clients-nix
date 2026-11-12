# cod-clients-nix

Community Call of Duty clients for NixOS: Plutonium, t7x, the AlterWare family
and more, run under umu-launcher and Proton. It is a Home Manager module for
people who own the games and want the modded clients without building a Wine
prefix by hand.

Each client runs inside a bubblewrap sandbox that hides your home directory
and shows it only the game files and its own state. The client programs are
fetched from their own servers at the first launch and keep themselves up to
date. You bring the games.

It runs on x86_64 Linux only. Start with Plutonium and Black Ops 1, Black Ops 2
or World at War. Every other client is experimental, and several have not been
verified from start to finish on Linux.

## What you get

| Command | Client | Game you bring |
|---|---|---|
| `cod-plutonium` | Plutonium | Black Ops 1, Black Ops 2, World at War, Modern Warfare 3 |
| `cod-t7x` | t7x | Black Ops III |
| `cod-boiii` | BOIII | Black Ops III |
| `cod-h1` | h1-mod | Modern Warfare Remastered |
| `cod-hmw` | Horizon MW | Modern Warfare Remastered |
| `cod-h2` | h2-mod | MW2 Campaign Remastered, which is not sold on Steam |
| `cod-iw5` | AlterWare iw5-mod | Modern Warfare 3 (2011) |
| `cod-iw6` | AlterWare iw6-mod | Ghosts |
| `cod-s1` | AlterWare s1-mod | Advanced Warfare |
| `cod-iw2` | AlterWare iw2-mod | Call of Duty 2 |
| `cod-cblauncher` | CB Launcher | a hub for about 17 community clients, which it downloads itself into a folder you name |

Every client is off until you enable it. The Steam app id of each game and the
notes for each client are in [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md).

## Install

Add the flake:

```nix
{
  inputs.cod-clients = {
    url = "github:Daaboulex/cod-clients-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Load the module from your NixOS configuration, then switch on the clients you
want in your Home Manager configuration:

```nix
{
  home-manager.sharedModules = [ inputs.cod-clients.homeModules.default ];
}
```

```nix
{
  myModules.home.cod-clients = {
    enable = true;
    plutonium.enable = true;
  };
}
```

The launchers are marked unfree, so nixpkgs has to allow unfree packages. After
a rebuild `cod-plutonium` is on your PATH and in your application menu.

## First run

Run `cod-plutonium` from a terminal the first time, so you see the setup and
any error. The first launch of a client is slow, once. It downloads umu's
Steam Runtime, builds the Wine prefix and fetches the client. For Plutonium
that takes several minutes.

Plutonium's own launcher then opens. Log in with your free Plutonium forum
account, point it at your Steam game folder and pick a title.

## Options you are likely to set

All of them sit under `myModules.home.cod-clients`. Every option, with its type
and default: [docs/OPTIONS.md](docs/OPTIONS.md).

| Option | What it is for |
|---|---|
| `protonPath` | The Proton the clients run under. The default is the GE-Proton pinned by nixpkgs. `"steam"` picks the newest one in Steam's `compatibilitytools.d` |
| `plutonium.dotnet` | Adds `dotnet472` to the Plutonium prefix, which Modern Warfare 3 needs. Off by default because the install is slow |
| `t7x.blackOps3Dir` | Where Black Ops III is, when it is not found in your Steam libraries. The other clients that look a game up in Steam have the same kind of option |
| `h2.mw2crDir` | Where MW2 Campaign Remastered is. `cod-h2` cannot find it on its own |
| `cblauncher.gameDirs` | The folders CB Launcher may write games into. Empty by default, so it can download nothing until you set it |

Two environment variables change one run without a rebuild.
`COD_PROTON=<path> cod-plutonium` runs it under another Proton, and
`COD_SANDBOX=0 cod-plutonium` runs it without the sandbox.

## Steam

Four optional helpers tie the clients into Steam. Each is off by default, is a
command you run yourself with Steam closed, and can be undone. How to run them
is in [docs/STEAM.md](docs/STEAM.md).

| Option | Command | What it does |
|---|---|---|
| `steamAdd.enable` | `cod-steam-add` | Adds every installed launcher to Steam as a non-Steam shortcut. The sandbox stays |
| `steamNative.enable` | `cod-steam-native` | Adds each client's `.exe` as a shortcut that Steam runs under its own Proton, so the Compatibility dropdown works. No sandbox |
| `steamLink.enable` | `cod-steamlink` | Swaps a Steam game's exe for Plutonium, so Play starts Plutonium and Steam counts the hours |
| `cleanops.enable` | `cod-cleanops` | Puts the CleanOps `d3d11.dll` into your retail Black Ops III |

## Known limits

- You must own the games. The launchers mod a copy you have and provide none.
- Modern Warfare 3 through Plutonium has an unfixed no-cursor bug on NixOS with
  GE-Proton.
- t7x is not tested on Linux by its upstream, and a codec error under Proton is
  reported with no confirmed fix.
- The AlterWare clients have not been verified from start to finish.
- BOIII's DXVK rendering is untested. It may only work as a dedicated server.

## When something does not work

- `no valid Proton`. `protonPath` is not a directory that holds a `proton`
  script. Leave it at the default, set it to `"steam"`, or use `COD_PROTON`.
- A game is not found. Set that client's directory option.
- "Steam must be installed", or Black Ops III says launching and then nothing
  happens. BOIII, t7x and CB Launcher's Black Ops III need the Steam client
  installed on the machine.
- A client works only with `COD_SANDBOX=0`. The sandbox is missing something
  the game needs. Use the bypass for now and please report it.

## More

- [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md): every client, the settings
  that belong in each game's own menu, troubleshooting in full
- [docs/STEAM.md](docs/STEAM.md): the four Steam helpers and how to undo each
- [docs/DESIGN.md](docs/DESIGN.md): where the clients come from, the sandbox,
  how Proton is chosen, how the games are found
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md): building and the checks
- [ARCHITECTURE.md](ARCHITECTURE.md): how the launchers are built
- [SECURITY.md](SECURITY.md): how to report a vulnerability

## License

The packaging in this repository is MIT, see [LICENSE](LICENSE). The clients themselves are
proprietary, third-party programs that are downloaded when you run them.
