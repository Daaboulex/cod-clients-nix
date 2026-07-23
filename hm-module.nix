{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myModules.home.cod-clients;
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
      in
      {
        iw5 = {
          enable = lib.mkEnableOption "the iw5-mod launcher (Modern Warfare 3, 2011) -- experimental";
          gameDir = gameDirOption "Modern Warfare 3 (2011)" "115300";
        };
        iw6 = {
          enable = lib.mkEnableOption "the iw6-mod launcher (Ghosts) -- experimental";
          gameDir = gameDirOption "Ghosts" "209160";
        };
        s1 = {
          enable = lib.mkEnableOption "the s1-mod launcher (Advanced Warfare) -- experimental";
          gameDir = gameDirOption "Advanced Warfare" "209650";
        };
        iw2 = {
          enable = lib.mkEnableOption "the iw2-mod launcher (Call of Duty 2) -- experimental";
          gameDir = gameDirOption "Call of Duty 2" "2630";
        };
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
      virtualDesktop = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          "cb-launcher.exe" = "auto";
        };
        example = {
          "cb-launcher.exe" = "2560x1440";
        };
        description = ''
          Wine virtual desktop for the CB prefix. A non-empty set enables a
          prefix-global desktop (the winecfg form Wine honors reliably) sized by
          the first value -- "auto" reads the primary display's current resolution
          at each launch (a changed screen applies on the next launch), or pin a
          WIDTHxHEIGHT: the launcher and every game it spawns
          render inside one Wine-managed surface, bypassing the compositor -- the
          fix for KDE Plasma 6 Wayland hiding cb-launcher's CEF dropdown popups
          and for cursor-escape and focus-loss crashes. Session-aware at launch:
          applied under Wayland, removed again on plain X11, so one config is
          correct on either. Games rerouted via subProton run in their own
          prefixes and are not affected. Set the resolution to your monitor's, or
          set to { } to disable entirely.
        '';
      };
      subProton = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              protonPath = lib.mkOption {
                type = lib.types.str;
                description = "Proton directory this game runs under, e.g. \"\${pkgs.proton-ge.v10.steamcompattool}\".";
              };
              gameDir = lib.mkOption {
                type = lib.types.str;
                description = "The CB-managed directory holding this game and its client exe (absolute path).";
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
              virtualDesktop = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
                description = "Per-exe Wine virtual desktop inside this game's own prefix (exe -> WIDTHxHEIGHT).";
              };
              env = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
                description = "Environment for this game's Proton session, e.g. PROTON_ENABLE_WAYLAND = \"1\".";
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
        inherit (cfg.t7x) blackOps3Dir;
        t7xExtraWinetricks = cfg.t7x.extraWinetricks;
        t7xExtraArgs = cfg.t7x.extraArgs;
        mwrDir = cfg.h1.mwrDir;
        h1ExtraArgs = cfg.h1.extraArgs;
        h1ExtraWinetricks = cfg.h1.extraWinetricks;
        mw2crDir = cfg.h2.mw2crDir;
        h2ExtraArgs = cfg.h2.extraArgs;
        h2ExtraWinetricks = cfg.h2.extraWinetricks;
        inherit (cfg) sandbox;
        hmwMwrDir = cfg.hmw.mwrDir;
        hmwExtraArgs = cfg.hmw.extraArgs;
        hmwExtraWinetricks = cfg.hmw.extraWinetricks;
        boiiiBlackOps3Dir = cfg.boiii.blackOps3Dir;
        boiiiExtraArgs = cfg.boiii.extraArgs;
        boiiiExtraWinetricks = cfg.boiii.extraWinetricks;
        iw5GameDir = cfg.alterware.iw5.gameDir;
        iw6GameDir = cfg.alterware.iw6.gameDir;
        s1GameDir = cfg.alterware.s1.gameDir;
        iw2GameDir = cfg.alterware.iw2.gameDir;
        cblauncherExtraArgs = cfg.cblauncher.extraArgs;
        cblauncherExtraWinetricks = cfg.cblauncher.extraWinetricks;
        cblauncherGameDirs = cfg.cblauncher.gameDirs;
        cblauncherGameSettings = cfg.cblauncher.gameSettings;
        cblauncherVirtualDesktop = cfg.cblauncher.virtualDesktop;
        cblauncherSubProton = cfg.cblauncher.subProton;
        cblauncherEnv = cfg.cblauncher.env;
        inherit (cfg) desktopEntries;
      };
    in
    {
      assertions = lib.mapAttrsToList (exe: sub: {
        assertion =
          lib.hasSuffix ".exe" (lib.toLower exe)
          && lib.hasPrefix "/" sub.gameDir
          && sub.protonPath != ""
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
