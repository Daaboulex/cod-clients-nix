{
  lib,
  callPackage,
  proton-ge-bin,
  alterware-launcher,
  jq,
  unzip,
}:

{
  protonPath ? "${proton-ge-bin.steamcompattool}",
  protonPaths ? { },
  plutoniumDotnet ? false,
  plutoniumExtraWinetricks ? [ ],
  plutoniumExtraArgs ? [ ],
  blackOps3Dir ? "",
  t7xExtraWinetricks ? [ ],
  t7xExtraArgs ? [ ],
  mwrDir ? "",
  h1ExtraArgs ? [ ],
  h1ExtraWinetricks ? [ ],
  mw2crDir ? "",
  h2ExtraArgs ? [ ],
  h2ExtraWinetricks ? [ ],
  sandbox ? true,
  hmwMwrDir ? "",
  hmwExtraArgs ? [ ],
  hmwExtraWinetricks ? [ ],
  boiiiBlackOps3Dir ? "",
  boiiiExtraArgs ? [ ],
  boiiiExtraWinetricks ? [ ],
  iw5GameDir ? "",
  iw6GameDir ? "",
  s1GameDir ? "",
  iw2GameDir ? "",
  cblauncherExtraArgs ? [ ],
  cblauncherExtraWinetricks ? [ ],
  cblauncherGameDirs ? [ ],
  cblauncherGameSettings ? { },
  cblauncherSubProton ? { },
  cblauncherLaunchOptions ? { },
  cblauncherConfigFiles ? { },
  maxFps ? null,
  cblauncherEnv ? { },
  plutoniumEnv ? { },
  t7xEnv ? { },
  h1Env ? { },
  h2Env ? { },
  hmwEnv ? { },
  boiiiEnv ? { },
  iw5ExtraWinetricks ? [ ],
  iw5ExtraArgs ? [ ],
  iw5Env ? { },
  iw6ExtraWinetricks ? [ ],
  iw6ExtraArgs ? [ ],
  iw6Env ? { },
  s1ExtraWinetricks ? [ ],
  s1ExtraArgs ? [ ],
  s1Env ? { },
  iw2ExtraWinetricks ? [ ],
  iw2ExtraArgs ? [ ],
  iw2Env ? { },
  desktopEntries ? { },
}:

let
  mk = callPackage ./. { };
  steamResolver = import ./steam-resolve.nix;
  steamlinkPkg = (callPackage ./steamlink.nix { }) { resolver = steamResolver; };
  steamaddPkg = callPackage ./steam-add.nix { };
  cleanopsPkg = (callPackage ./cleanops.nix { }) { resolver = steamResolver; };
  steamnativePkg = callPackage ./steam-native.nix { };
  protonpickerPkg = callPackage ./proton.nix { };

  plutoniumBaseVerbs = [
    "corefonts"
    "msasn1"
    "vcrun2005"
    "vcrun2008"
    "vcrun2012"
    "vcrun2019"
    "d3dcompiler_47"
    "d3dcompiler_43"
    "d3dx9"
    "d3dx10"
    "d3dx11_42"
    "d3dx11_43"
    "xact"
    "xact_x64"
    "xinput"
    "physx"
    "mdac28"
    "win10"
    "grabfullscreen=y"
  ];

  cbBaseVerbs = [
    "corefonts"
    "vcrun2005"
    "vcrun2008"
    "vcrun2010"
    "vcrun2012"
    "vcrun2013"
    "vcrun2022"
    "d3dcompiler_43"
    "d3dcompiler_47"
    "d3dx9"
    "d3dx10"
    "d3dx11_43"
    "xact"
    "xact_x64"
    "xinput"
    "physx"
  ];

  cbPrefixVerbs = cbBaseVerbs ++ [
    "dotnet472"
    "msasn1"
    "win10"
    "grabfullscreen=y"
  ];

  plutoniumSubVerbs = cbBaseVerbs ++ [
    "msasn1"
    "vcrun2019"
    "d3dx11_42"
    "win10"
    "grabfullscreen=y"
  ];

  subVerbsFor = exe: if exe == "plutonium.exe" then plutoniumSubVerbs else cbBaseVerbs;

  subDirFor =
    exe:
    {
      "s1x.exe" = "aw_game_files";
      "iw6x.exe" = "ghosts_game_files";
      "iw3mp.exe" = "cod4_game_files";
      "iw3sp.exe" = "cod4_game_files";
      "plutonium.exe" = "mw3_game_files";
      "iw4x.exe" = "mw2_game_files";
      "boiii.exe" = "bo3_game_files";
      "h1-mod.exe" = "mwr_game_files";
      "iw7-mod.exe" = "iw_game_files";
    }
    .${exe} or null;

  subGameDir =
    exe: sub:
    let
      explicit = sub.gameDir or null;
      derived = subDirFor exe;
    in
    if explicit != null then
      explicit
    else if derived != null && cblauncherGameDirs != [ ] then
      "${lib.head cblauncherGameDirs}/${derived}"
    else
      throw "cod-cbsub: no gameDir for ${exe} -- set subProton.\"${exe}\".gameDir or add a cblauncher.gameDirs root and use a known exe";

  subArgsFor =
    exe:
    if maxFps == null then
      [ ]
    else if
      lib.elem exe [
        "s1x.exe"
        "iw3mp.exe"
      ]
    then
      [ "+set com_maxfps ${toString maxFps}" ]
    else
      [ ];

  subEnvFor =
    exe:
    if exe == "s1x.exe" then
      {
        PROTON_USE_WAYLAND = "1";
        PROTON_USE_SDL = "1";
        VKD3D_CONFIG = "descriptor_heap";
      }
    else
      { };

  subSlug =
    exe: lib.toLower (lib.replaceStrings [ " " "." ] [ "-" "-" ] (lib.removeSuffix ".exe" exe));

  cbsubs = lib.mapAttrs (
    exe: sub:
    mk {
      name = "cbsub-${subSlug exe}";
      desktopName = "CB ${exe}";
      desktopEntry = false;
      inherit sandbox;
      protonPath = if (sub.protonPath or null) == null then protonPath else sub.protonPath;
      winetricks = subVerbsFor exe ++ (sub.extraWinetricks or [ ]);
      env = subEnvFor exe // (sub.env or { });
      extraArgs = subArgsFor exe ++ (sub.extraArgs or [ ]);
      preLaunch = ''
        cod_rw_dirs=${
          lib.escapeShellArg (
            lib.concatStringsSep "\n" ([ (subGameDir exe sub) ] ++ (sub.extraGameDirs or [ ]))
          )
        }
        while IFS= read -r d; do
          [ -n "$d" ] && mkdir -p "$d"
        done <<< "$cod_rw_dirs"
        gamedir_rw=${lib.escapeShellArg (subGameDir exe sub)}
        run=${lib.escapeShellArg "${subGameDir exe sub}/${exe}"}
        cd "$gamedir_rw"
      '';
    }
  ) cblauncherSubProton;

  mkAlterware =
    {
      name,
      desktopName,
      code,
      appid,
      exe,
      modes ? [ ],
      gameDir ? "",
      winetricks ? [ ],
      extraArgs ? [ ],
      env ? { },
      desktopEntry ? true,
    }:
    mk {
      inherit
        name
        desktopName
        sandbox
        desktopEntry
        winetricks
        env
        ;
      protonPath = protonPaths.${name} or protonPath;
      extraRuntimeInputs = [ alterware-launcher ];
      extraArgs = modes ++ extraArgs;
      acquire = ''
        gamedir="${gameDir}"
        if [ -z "$gamedir" ]; then
          gamedir="$(resolve_steam_dir ${appid} || true)"
        fi
        if [ -z "$gamedir" ] || [ ! -d "$gamedir" ]; then
          echo "cod-${name}: ${desktopName} base game not found (own + install it on Steam, app ${appid}, or set alterware.${name}.gameDir to an existing install)" >&2
          exit 1
        fi
        echo "cod-${name}: updating ${code} via alterware-launcher"
        alterware-launcher ${code} -p "$gamedir" -u --skip-launcher-update
        gamedir_rw="$gamedir"
        run="$gamedir/${exe}"
        cd "$gamedir"
      '';
    };

  mkFarmClient =
    {
      name,
      desktopName,
      gameName,
      appid,
      url,
      exe,
      dirOverride ? "",
      extraArgs ? [ ],
      realCopyExe ? null,
      winetricks ? [ ],
      env ? { },
      desktopEntry ? true,
    }:
    mk {
      inherit
        name
        desktopName
        sandbox
        url
        exe
        extraArgs
        winetricks
        desktopEntry
        env
        ;
      protonPath = protonPaths.${name} or protonPath;
      preLaunch = ''
        gd="${dirOverride}"
        ${lib.optionalString (appid != "") ''
          if [ -z "$gd" ]; then
            gd="$(resolve_steam_dir ${appid} || true)"
          fi
        ''}
        if [ -z "$gd" ] || [ ! -d "$gd" ]; then
          echo "cod-${name}: ${gameName} not found${
            if appid != "" then
              " (own + install it on Steam, app ${appid})"
            else
              "; set this client's game directory option (this title is not sold on Steam)"
          }" >&2
          exit 1
        fi
        gamedir="$gd"

        farm="$state/game"
        if [ ! -f "$state/.farm-ready" ]; then
          echo "cod-${name}: building the game farm from $gd"
          rm -rf "$farm"
          mkdir -p "$farm"
          cp -rs "$gd/." "$farm/"
          ${lib.optionalString (realCopyExe != null) ''
            cp -f --remove-destination --no-preserve=mode "$gd/${realCopyExe}" "$farm/${realCopyExe}"
          ''}
          rm -f "$farm/d3d11.dll"
          touch "$state/.farm-ready"
        fi
        ln -sfn "$state/${exe}" "$farm/${exe}"

        run="$farm/${exe}"
        cd "$farm" || exit 1
      '';
    };
in
{
  plutonium = mk {
    name = "plutonium";
    desktopEntry = desktopEntries.plutonium or true;
    inherit sandbox;
    desktopName = "Plutonium";
    url = "https://cdn.plutonium.pw/updater/plutonium.exe";
    exe = "plutonium.exe";
    protonPath = protonPaths.plutonium or protonPath;
    winetricks =
      plutoniumBaseVerbs ++ lib.optional plutoniumDotnet "dotnet472" ++ plutoniumExtraWinetricks;
    env = lib.optionalAttrs plutoniumDotnet { WINEDLLOVERRIDES = "mscoree="; } // plutoniumEnv;
    extraArgs = plutoniumExtraArgs;
  };

  t7x = mkFarmClient {
    name = "t7x";
    desktopEntry = desktopEntries.t7x or true;
    desktopName = "Call of Duty: Black Ops III (t7x)";
    gameName = "Black Ops III";
    appid = "311210";
    url = "https://master.bo3.eu/t7x/t7x.exe";
    exe = "t7x.exe";
    dirOverride = blackOps3Dir;
    realCopyExe = "BlackOps3.exe";
    winetricks = t7xExtraWinetricks;
    extraArgs = t7xExtraArgs;
    env = t7xEnv;
  };

  h1 = mkFarmClient {
    name = "h1";
    desktopEntry = desktopEntries.h1 or true;
    desktopName = "Call of Duty: Modern Warfare Remastered (h1-mod)";
    gameName = "Modern Warfare Remastered";
    appid = "393080";
    url = "https://github.com/auroramod/h1-mod/releases/latest/download/h1-mod.exe";
    exe = "h1-mod.exe";
    dirOverride = mwrDir;
    winetricks = h1ExtraWinetricks;
    extraArgs = h1ExtraArgs;
    env = h1Env;
  };

  h2 = mkFarmClient {
    name = "h2";
    desktopEntry = desktopEntries.h2 or true;
    desktopName = "Call of Duty: Modern Warfare 2 Campaign Remastered (h2-mod)";
    gameName = "Modern Warfare 2 Campaign Remastered";
    appid = "";
    url = "https://h2-mod.alicent.cat/data/h2-mod.exe";
    exe = "h2-mod.exe";
    dirOverride = mw2crDir;
    winetricks = h2ExtraWinetricks;
    extraArgs = h2ExtraArgs;
    env = h2Env;
  };

  hmw = mk {
    name = "hmw";
    desktopEntry = desktopEntries.hmw or true;
    inherit sandbox;
    desktopName = "Horizon MW";
    protonPath = protonPaths.hmw or protonPath;
    extraRuntimeInputs = [ unzip ];
    winetricks = [
      "vcrun2022"
      "corefonts"
      "dotnetdesktop8"
    ]
    ++ hmwExtraWinetricks;
    env = hmwEnv;
    extraArgs = hmwExtraArgs;
    acquire = ''
      gd="${hmwMwrDir}"
      if [ -z "$gd" ]; then
        gd="$(resolve_steam_dir 393080 || true)"
      fi
      if [ -z "$gd" ] || [ ! -d "$gd" ]; then
        echo "cod-hmw: Modern Warfare Remastered not found (install it on Steam, app 393080) or set hmw.mwrDir" >&2
        exit 1
      fi
      gamedir="$gd"

      farm="$state/game"
      if [ ! -f "$state/.farm-ready" ]; then
        echo "cod-hmw: building MWR game farm from $gd"
        rm -rf "$farm"
        mkdir -p "$farm"
        cp -rs "$gd/." "$farm/"
        touch "$state/.farm-ready"
      fi

      if [ ! -f "$state/HMW Launcher.exe" ]; then
        echo "cod-hmw: fetching Horizon MW Launcher"
        curl -fL --remove-on-error --output "$state/HMW_Launcher.zip" \
          "https://ghost.cdn.horizonmw.org/launcher/HMW_Launcher.zip"
        unzip -o "$state/HMW_Launcher.zip" -d "$state/"
      fi
      run="$state/HMW Launcher.exe"
      cd "$farm" || exit 1
    '';
    preLaunch = ''
      echo "cod-hmw: Horizon MW will download mod files into this game directory on first run."
    '';
  };

  boiii = mkFarmClient {
    name = "boiii";
    desktopEntry = desktopEntries.boiii or true;
    desktopName = "Call of Duty: Black Ops III (BOIII)";
    gameName = "Black Ops III";
    appid = "311210";
    url = "https://github.com/Ezz-lol/boiii-free/releases/latest/download/boiii.exe";
    exe = "boiii.exe";
    dirOverride = boiiiBlackOps3Dir;
    winetricks = boiiiExtraWinetricks;
    extraArgs = [
      "-nosteam"
      "-launch"
      "-nointro"
    ]
    ++ boiiiExtraArgs;
    env = boiiiEnv;
  };

  cblauncher = mk {
    name = "cblauncher";
    desktopEntry = desktopEntries.cblauncher or true;
    inherit sandbox;
    desktopName = "CB Launcher";
    protonPath = protonPaths.cblauncher or protonPath;
    url = "https://github.com/CBServers/updater/raw/main/updater/cb-launcher/cb-launcher.exe";
    exe = "cb-launcher.exe";
    winetricks = cbPrefixVerbs ++ cblauncherExtraWinetricks;
    extraRuntimeInputs = [ jq ];
    gameSettings = cblauncherGameSettings;
    subWatch = lib.mapAttrs (_: p: lib.getExe p) cbsubs;
    env = cblauncherEnv;
    extraArgs = [
      "-portable"
      "--in-process-gpu"
      "--disable-gpu"
      "--disable-gpu-compositing"
      "--disable-direct-composition"
      "--disable-features=CalculateNativeWinOcclusion"
    ]
    ++ cblauncherExtraArgs;
    preLaunch = ''
      ${lib.optionalString (cblauncherConfigFiles != { }) ''
                cod_seta() {
                  if grep -q "^seta $2 " "$1" 2>/dev/null; then
                    sed -i "s|^seta $2 .*|seta $2 \"$3\"|" "$1"
                  else
                    printf 'seta %s "%s"\n' "$2" "$3" >> "$1"
                  fi
                }
                while IFS= read -r cod_root; do
                  [ -n "$cod_root" ] || continue
        ${
          lib.concatStrings (
            lib.mapAttrsToList (
              rel: settings:
              "          if [ -d \"$cod_root/"
              + dirOf rel
              + "\" ] || [ -d \"$cod_root/"
              + lib.head (lib.splitString "/" rel)
              + "\" ]; then\n"
              + "            mkdir -p \"$cod_root/"
              + dirOf rel
              + "\"\n"
              + "            touch \"$cod_root/"
              + rel
              + "\"\n"
              + lib.concatStrings (
                lib.mapAttrsToList (
                  k: v:
                  "            cod_seta \"$cod_root/"
                  + rel
                  + "\" "
                  + lib.escapeShellArg k
                  + " "
                  + lib.escapeShellArg v
                  + "\n"
                ) settings
              )
              + "          fi\n"
            ) cblauncherConfigFiles
          )
        }        done <<< "$cod_rw_dirs"
      ''}
      ${lib.optionalString (cblauncherLaunchOptions != { }) ''
        cod_props="$state/cbservers/user/properties.json"
        cod_lo=${
          lib.escapeShellArg (
            builtins.toJSON (
              lib.mapAttrs' (g: v: lib.nameValuePair "${g}-launch-options" v) cblauncherLaunchOptions
            )
          )
        }
        mkdir -p "$state/cbservers/user"
        if [ -s "$cod_props" ]; then
          jq -S -s '.[0] * .[1]' "$cod_props" <(printf '%s' "$cod_lo") > "$cod_props.tmp"
          mv "$cod_props.tmp" "$cod_props"
        else
          printf '%s' "$cod_lo" > "$cod_props"
        fi
      ''}
      cod_rw_dirs=${lib.escapeShellArg (lib.concatStringsSep "\n" cblauncherGameDirs)}
      while IFS= read -r d; do
        [ -n "$d" ] && mkdir -p "$d"
      done <<< "$cod_rw_dirs"
    '';
  };

  steamlink = steamlinkPkg;
  steamadd = steamaddPkg;
  cleanops = cleanopsPkg;
  steamnative = steamnativePkg;
  protonpicker = protonpickerPkg;

  iw5 = mkAlterware {
    name = "iw5";
    desktopEntry = desktopEntries.iw5 or true;
    desktopName = "Call of Duty: Modern Warfare 3 (iw5-mod)";
    code = "iw5-mod";
    appid = "115300";
    exe = "iw5-mod.exe";
    modes = [ "-multiplayer" ];
    gameDir = iw5GameDir;
    winetricks = iw5ExtraWinetricks;
    extraArgs = iw5ExtraArgs;
    env = iw5Env;
  };
  iw6 = mkAlterware {
    name = "iw6";
    desktopEntry = desktopEntries.iw6 or true;
    desktopName = "Call of Duty: Ghosts (iw6-mod)";
    code = "iw6-mod";
    appid = "209160";
    exe = "iw6-mod.exe";
    modes = [ "-multiplayer" ];
    gameDir = iw6GameDir;
    winetricks = iw6ExtraWinetricks;
    extraArgs = iw6ExtraArgs;
    env = iw6Env;
  };
  s1 = mkAlterware {
    name = "s1";
    desktopEntry = desktopEntries.s1 or true;
    desktopName = "Call of Duty: Advanced Warfare (s1-mod)";
    code = "s1-mod";
    appid = "209650";
    exe = "s1-mod.exe";
    modes = [ "-multiplayer" ];
    gameDir = s1GameDir;
    winetricks = s1ExtraWinetricks;
    extraArgs = s1ExtraArgs;
    env = s1Env;
  };
  iw2 = mkAlterware {
    name = "iw2";
    desktopEntry = desktopEntries.iw2 or true;
    desktopName = "Call of Duty 2 (iw2-mod)";
    code = "iw2-mod";
    appid = "2630";
    exe = "iw2-mod.exe";
    modes = [ ];
    gameDir = iw2GameDir;
    winetricks = iw2ExtraWinetricks;
    extraArgs = iw2ExtraArgs;
    env = iw2Env;
  };
}
