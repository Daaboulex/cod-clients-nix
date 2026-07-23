{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  cfg = config.myModules.home.cod-clients;
  displayMonitors =
    if
      osConfig ? myModules && osConfig.myModules ? desktop && osConfig.myModules.desktop ? displays
    then
      osConfig.myModules.desktop.displays.monitors or { }
    else
      { };
  maxRefreshHz = lib.foldl' lib.max 0 (
    map (m: m.mode.refreshRate / 1000) (lib.attrValues displayMonitors)
  );
  derivedMaxFps = if maxRefreshHz > 0 then maxRefreshHz - 2 else null;
  fpsGames = [
    "cod4x"
    "t4"
    "t5"
    "t6"
    "iw5"
    "mw2"
    "mwr"
    "mw2r"
    "hmw"
    "iw"
  ];
  fpsLaunchDefaults =
    if cfg.maxFps == null then
      { }
    else
      lib.genAttrs fpsGames (_: "+set com_maxfps ${toString cfg.maxFps}");
  ghostsDisplaySettings = {
    r_displayMode = "windowed (no border)";
    r_monitor = "0";
    vid_xpos = "0";
    vid_ypos = "0";
    cl_bypassMouseInput = "1";
  }
  // lib.optionalAttrs (cfg.maxFps != null) {
    com_maxfps = toString cfg.maxFps;
  };
in
{
  options.myModules.home.cod-clients = {
    enable = lib.mkEnableOption "the community Call of Duty client launchers (umu + Proton + bubblewrap)";

    protonPath = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.proton-ge-bin.steamcompattool}";
      defaultText = lib.literalExpression ''"''${pkgs.proton-ge-bin.steamcompattool}"'';
      description = ''
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
      '';
    };

    protonPaths = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''
        {
          s1 = "''${pkgs.proton-ge.v10.steamcompattool}";
          iw6 = "''${pkgs.proton-ge.v10.steamcompattool}";
        }
      '';
      description = ''
        Per-client Proton overrides, keyed by client name (plutonium, t7x, h1, h2,
        hmw, boiii, cblauncher, iw5, iw6, s1, iw2). A client absent from this set uses
        the global `protonPath`. Each standalone client is its own umu session and
        prefix, so different clients can run different wine majors from one config.
        CB Launcher is one process tree: every game it spawns is a plain child
        process inheriting the cblauncher entry, so a per-game Proton through CB
        does not exist.
      '';
    };

    maxFps = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = derivedMaxFps;
      defaultText = lib.literalExpression "highest declared monitor refresh minus 2, null without a displays module";
      description = ''
        Frame cap injected into every client that verifiably consumes
        com_maxfps: the CB-managed arg-consuming games via launchOptions, the
        rerouted prefixes via their default arguments, and Ghosts via its
        config files. Derived from the host displays module so a 240 Hz panel
        yields 237 and the cap stays inside the adaptive-sync window; null
        disables injection. Black Ops III caps at 250 in its own menu and
        Black Ops 4 carries no verified cap surface -- both stay manual.
      '';
    };

    sandbox = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run every client inside a bubblewrap sandbox that exposes only game files
        (Steam libraries, read-only), the client's own prefix/state (read-write),
        and GPU/audio/input/display/network -- no $HOME or unrelated files. Set the
        COD_SANDBOX=0 environment variable at runtime to bypass it for one launch.
      '';
    };

    desktopEntries = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = { };
      example = {
        boiii = false;
      };
      description = ''
        Per-client app-drawer control, keyed by client name (plutonium, t7x, h1, h2,
        hmw, boiii, cblauncher, iw5, iw6, s1, iw2). A client absent from this set gets a
        .desktop entry (shown in the app drawer); set it to false to install the launcher
        without a drawer entry, for Steam-only or CLI-only use.
      '';
    };

    plutonium = {
      enable = lib.mkEnableOption "the Plutonium client launcher (Black Ops 1/2, MW3, WaW)";
      dotnet = lib.mkEnableOption ''
        MW3/IW5 support in the Plutonium prefix (installs dotnet472). Slower first-run,
        and MW3/IW5 has an unfixed no-cursor bug on NixOS + GE-Proton'';
      extraWinetricks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra winetricks verbs added to the Plutonium prefix.";
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments passed to plutonium.exe (advanced/LAN use).";
      };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = \"1\".";
      };
    };

    t7x = {
      enable = lib.mkEnableOption "the t7x client launcher (Black Ops III) -- experimental on Linux";
      blackOps3Dir = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Path to the owned retail Black Ops III Steam install directory. Empty =
          auto-detect from Steam's libraryfolders.vdf (app 311210).
        '';
      };
      extraWinetricks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Extra winetricks verbs for the t7x prefix, e.g. [ "mf" "mfplat" ] if you hit
          the media-foundation codec error.
        '';
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments passed to t7x.exe.";
      };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = \"1\".";
      };
    };

    h1 = {
      enable = lib.mkEnableOption "the h1-mod launcher (Modern Warfare Remastered, Aurora) -- experimental";
      mwrDir = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Path to the owned Modern Warfare Remastered Steam install directory. Empty =
          auto-detect from Steam's libraryfolders.vdf (app 393080).
        '';
      };
      extraWinetricks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra winetricks verbs added to the h1-mod prefix.";
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments passed to h1-mod.exe.";
      };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = \"1\".";
      };
    };

    h2 = {
      enable = lib.mkEnableOption "the h2-mod launcher (Modern Warfare 2 Campaign Remastered, Aurora) -- experimental";
      mw2crDir = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Path to the owned Modern Warfare 2 Campaign Remastered install directory.
          MW2CR is not sold on Steam (PC release is Battle.net-only), so it cannot be
          auto-detected -- set this explicitly to your installed game directory.
        '';
      };
      extraWinetricks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra winetricks verbs added to the h2-mod prefix.";
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments passed to h2-mod.exe.";
      };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = \"1\".";
      };
    };

    alterware =
      let
        gameDirOption =
          game: appid:
          lib.mkOption {
            type = lib.types.str;
            default = "";
            description = ''
              Path to an existing ${game} install directory (any source, e.g. a CB
              Launcher download dir). Empty = auto-detect from Steam's
              libraryfolders.vdf (app ${appid}). The alterware-launcher lays its
              client files into this directory on each run.
            '';
          };
        clientOptions = game: appid: exe: {
          enable = lib.mkEnableOption "the ${exe} launcher (${game}) -- experimental";
          gameDir = gameDirOption game appid;
          extraWinetricks = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Winetricks verbs installed into this client's own prefix.";
          };
          extraArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Extra arguments passed to ${exe}.";
          };
          env = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = \"1\".";
          };
        };
      in
      {
        iw5 = clientOptions "Modern Warfare 3 (2011)" "115300" "iw5-mod";
        iw6 = clientOptions "Ghosts" "209160" "iw6-mod";
        s1 = clientOptions "Advanced Warfare" "209650" "s1-mod";
        iw2 = clientOptions "Call of Duty 2" "2630" "iw2-mod";
      };

    hmw = {
      enable = lib.mkEnableOption "the Horizon MW launcher (Modern Warfare Remastered mod) -- experimental, default-off";
      mwrDir = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Path to the owned Modern Warfare Remastered Steam install directory. Empty =
          auto-detect from Steam's libraryfolders.vdf (app 393080).
        '';
      };
      extraWinetricks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra winetricks verbs added to the Horizon MW prefix.";
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments passed to Horizon MW Launcher.";
      };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = \"1\".";
      };
    };

    boiii = {
      enable = lib.mkEnableOption "the BOIII client (Black Ops III) -- experimental, default-off";
      blackOps3Dir = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Path to the owned Black Ops III Steam install directory. Empty =
          auto-detect from Steam's libraryfolders.vdf (app 311210).
        '';
      };
      extraWinetricks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Extra winetricks verbs for the BOIII prefix, e.g. [ "mf" "mfplat" ] if you hit
          the media-foundation codec error (same class as t7x).
        '';
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments passed to boiii.exe.";
      };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Environment for this client's Proton session, e.g. PROTON_NO_NTSYNC = \"1\".";
      };
    };

    cblauncher = {
      enable = lib.mkEnableOption "the CB Launcher for community CoD clients -- experimental, default-off";
      gameDirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "/home/you/Games/cod" ];
        description = ''
          Directories CB Launcher may download, patch, and manage games in, each bound
          read-write in its sandbox. Default empty = fail closed (only its own state is
          writable, so its game download/patch paths cannot run). List a writable
          fresh-download folder and/or existing game install dirs; then paste the matching
          path into CB Launcher's UI (its Browse button is disabled under Wine, so you type
          the path). The launcher creates any missing listed directory on start.
        '';
      };
      extraWinetricks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "dotnet472"
          "mf"
          "mfplat"
        ];
        description = ''
          Extra winetricks verbs for the CB Launcher prefix, added on top of its base set.
          Use this for a sub-client's own dependency (e.g. dotnet472 for its Plutonium MW3,
          or mf/mfplat for its BOIII codec path) -- the whole CB prefix is shared, so a verb
          added here is available to every game it manages.
        '';
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Extra arguments passed to cb-launcher.exe, appended after the packaged
          -portable and --in-process-gpu flags.
        '';
      };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = ''
          Environment for the CB Launcher Proton session and every game it starts
          in its prefix, e.g. PROTON_ENABLE_WAYLAND = "1".
        '';
      };
      gameSettings = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              registry = lib.mkOption {
                type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
                default = { };
                description = ''
                  String values written under HKCU\Software\Wine\AppDefaults\<exe>\<subkey>,
                  keyed subkey -> value name -> data. The "" subkey is the exe's root key
                  (e.g. Version = "win7"); other Wine keys scope the same way (DllOverrides,
                  "X11 Driver"). Applied via regedit when the settings change; exes removed
                  from this option get their AppDefaults key deleted.
                '';
              };
              dxvk = lib.mkOption {
                type = lib.types.lines;
                default = "";
                description = "dxvk.conf options for this executable's config section.";
              };
            };
          }
        );
        default = { };
        example = lib.literalExpression ''
          {
            "iw5mp.exe" = {
              registry."" .Version = "win7";
              registry."X11 Driver".GrabFullscreen = "Y";
              dxvk = "d3d9.maxFrameRate = 240";
            };
          }
        '';
        description = ''
          Per-game settings inside the shared CB Launcher prefix, keyed by the
          executable name as Wine sees it. Wine scopes AppDefaults registry
          entries and DXVK scopes config-file sections per executable, so each
          game CB launches can carry its own Windows version, DLL overrides,
          mouse capture, and DXVK options. The Proton build, the ntsync/esync
          class, and the sandbox shape stay launcher-wide (one process tree).
        '';
      };
      launchOptions = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = fpsLaunchDefaults;
        defaultText = lib.literalExpression "per-game +set com_maxfps maxFps for the arg-consuming clients";
        example = {
          iw5 = "+vid_restart";
        };
        description = ''
          Per-game launch options seeded into CB Launcher's properties.json
          (<game>-launch-options keys) before each start -- the launcher UI has
          no field for them under Wine. CB appends them to the game's command
          line. The ghosts default routes mouse input past the raw-input path
          that XWayland starves on Wayland desktops, which makes the menu
          usable. Set a game's key to "" to seed nothing for it.
        '';
      };
      configFiles = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
        default = {
          "ghosts_game_files/players2/config.cfg" = ghostsDisplaySettings;
          "ghosts_game_files/players2/config_mp.cfg" = ghostsDisplaySettings;
        };
        defaultText = lib.literalExpression "Ghosts borderless-on-primary display settings plus com_maxfps";
        example = lib.literalExpression ''
          {
            "cod4_game_files/main/autoexec_mp.cfg" = {
              raw_input = "1";
            };
          }
        '';
        description = ''
          Declarative seta enforcement in game config files, keyed by a path
          relative to each cblauncher.gameDirs root -> dvar -> value. Before
          every launch each existing root has matching files upserted: a
          present seta line is rewritten to the declared value, a missing one
          is appended, so whatever a game saves on exit is reasserted next
          start. The default forces Ghosts into borderless on the primary
          monitor, which sidesteps its exclusive-fullscreen display switching
          (the multi-monitor crash and alt-tab kill class) and keeps its menu
          mouse routed and its frame cap applied.
        '';
      };
      subProton = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              protonPath = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Proton directory this game runs under, e.g. \"\${pkgs.proton-ge.v10.steamcompattool}\"; null inherits the global protonPath.";
              };
              gameDir = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "The CB-managed directory holding this game and its client exe (absolute path); null derives <first gameDirs root>/<game>_game_files for the known exes.";
              };
              extraGameDirs = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = ''
                  Additional CB-managed game directories this exe must see (absolute
                  paths), bound read-write into its sandbox -- e.g. the WaW/BO1/BO2
                  directories for plutonium.exe, which serves several titles.
                '';
              };
              winetricks = lib.mkOption {
                type = lib.types.nullOr (lib.types.listOf lib.types.str);
                default = null;
                description = "Winetricks verbs for this game's own prefix; null uses the CB base verb set.";
              };
              extraArgs = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Arguments always passed to the game, before the ones CB supplied.";
              };
              env = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
                description = "Environment for this game's Proton session, e.g. PROTON_NO_NTSYNC = \"1\".";
              };
            };
          }
        );
        default = { };
        example = lib.literalExpression ''
          {
            "s1x.exe" = {
              protonPath = "''${pkgs.proton-ge.v10.steamcompattool}";
              gameDir = "/home/user/Games/CoD/aw_game_files";
            };
          }
        '';
        description = ''
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
        '';
      };
    };

    steamAdd.enable = lib.mkEnableOption "the cod-steam-add helper (registers installed clients as non-Steam shortcuts running the sandboxed native launcher; Proton via per-shortcut launch options)";
    steamNative.enable = lib.mkEnableOption "the cod-steam-native helper (registers each client's Windows .exe as a Steam shortcut under Steam's own Proton, so the Compatibility dropdown works; per-mode Plutonium + cover art)";
    steamLink.enable = lib.mkEnableOption "the cod-steamlink helper (reversible exe-swap so a Steam game's Play button launches Plutonium and tracks hours)";
    cleanops.enable = lib.mkEnableOption "the cod-cleanops helper (drops the CleanOps d3d11.dll into retail Black Ops III for Steam-launched multiplayer)";
  };

  config = lib.mkIf cfg.enable (
    let
      clients = (pkgs.callPackage ./pkgs/cod-launcher/clients.nix { }) {
        inherit (cfg) protonPath protonPaths;
        plutoniumDotnet = cfg.plutonium.dotnet;
        plutoniumExtraWinetricks = cfg.plutonium.extraWinetricks;
        plutoniumExtraArgs = cfg.plutonium.extraArgs;
        plutoniumEnv = cfg.plutonium.env;
        inherit (cfg.t7x) blackOps3Dir;
        t7xExtraWinetricks = cfg.t7x.extraWinetricks;
        t7xExtraArgs = cfg.t7x.extraArgs;
        t7xEnv = cfg.t7x.env;
        mwrDir = cfg.h1.mwrDir;
        h1ExtraArgs = cfg.h1.extraArgs;
        h1Env = cfg.h1.env;
        h1ExtraWinetricks = cfg.h1.extraWinetricks;
        mw2crDir = cfg.h2.mw2crDir;
        h2ExtraArgs = cfg.h2.extraArgs;
        h2Env = cfg.h2.env;
        h2ExtraWinetricks = cfg.h2.extraWinetricks;
        inherit (cfg) sandbox;
        hmwMwrDir = cfg.hmw.mwrDir;
        hmwExtraArgs = cfg.hmw.extraArgs;
        hmwEnv = cfg.hmw.env;
        hmwExtraWinetricks = cfg.hmw.extraWinetricks;
        boiiiBlackOps3Dir = cfg.boiii.blackOps3Dir;
        boiiiExtraArgs = cfg.boiii.extraArgs;
        boiiiEnv = cfg.boiii.env;
        boiiiExtraWinetricks = cfg.boiii.extraWinetricks;
        iw5GameDir = cfg.alterware.iw5.gameDir;
        iw5ExtraWinetricks = cfg.alterware.iw5.extraWinetricks;
        iw5ExtraArgs = cfg.alterware.iw5.extraArgs;
        iw5Env = cfg.alterware.iw5.env;
        iw6GameDir = cfg.alterware.iw6.gameDir;
        iw6ExtraWinetricks = cfg.alterware.iw6.extraWinetricks;
        iw6ExtraArgs = cfg.alterware.iw6.extraArgs;
        iw6Env = cfg.alterware.iw6.env;
        s1GameDir = cfg.alterware.s1.gameDir;
        s1ExtraWinetricks = cfg.alterware.s1.extraWinetricks;
        s1ExtraArgs = cfg.alterware.s1.extraArgs;
        s1Env = cfg.alterware.s1.env;
        iw2GameDir = cfg.alterware.iw2.gameDir;
        iw2ExtraWinetricks = cfg.alterware.iw2.extraWinetricks;
        iw2ExtraArgs = cfg.alterware.iw2.extraArgs;
        iw2Env = cfg.alterware.iw2.env;
        cblauncherExtraArgs = cfg.cblauncher.extraArgs;
        cblauncherExtraWinetricks = cfg.cblauncher.extraWinetricks;
        cblauncherGameDirs = cfg.cblauncher.gameDirs;
        cblauncherGameSettings = cfg.cblauncher.gameSettings;
        cblauncherSubProton = cfg.cblauncher.subProton;
        cblauncherLaunchOptions = cfg.cblauncher.launchOptions;
        cblauncherConfigFiles = cfg.cblauncher.configFiles;
        inherit (cfg) maxFps;
        cblauncherEnv = cfg.cblauncher.env;
        inherit (cfg) desktopEntries;
      };
    in
    {
      assertions = lib.mapAttrsToList (exe: sub: {
        assertion =
          lib.hasSuffix ".exe" (lib.toLower exe)
          && lib.hasPrefix "/" sub.gameDir
          && lib.all (d: lib.hasPrefix "/" d) sub.extraGameDirs;
        message = "cod-clients.cblauncher.subProton.\"${exe}\": the key must end in .exe, gameDir and every extraGameDirs entry must be absolute paths, and protonPath must be non-empty.";
      }) cfg.cblauncher.subProton;

      home.packages =
        lib.optional (cfg.protonPath == "steam") clients.protonpicker
        ++ lib.optional cfg.plutonium.enable clients.plutonium
        ++ lib.optional cfg.t7x.enable clients.t7x
        ++ lib.optional cfg.h1.enable clients.h1
        ++ lib.optional cfg.h2.enable clients.h2
        ++ lib.optional cfg.alterware.iw5.enable clients.iw5
        ++ lib.optional cfg.alterware.iw6.enable clients.iw6
        ++ lib.optional cfg.alterware.s1.enable clients.s1
        ++ lib.optional cfg.alterware.iw2.enable clients.iw2
        ++ lib.optional cfg.hmw.enable clients.hmw
        ++ lib.optional cfg.boiii.enable clients.boiii
        ++ lib.optional cfg.cblauncher.enable clients.cblauncher
        ++ lib.optional cfg.steamAdd.enable clients.steamadd
        ++ lib.optional cfg.steamNative.enable clients.steamnative
        ++ lib.optional cfg.steamLink.enable clients.steamlink
        ++ lib.optional cfg.cleanops.enable clients.cleanops;
    }
  );
}
