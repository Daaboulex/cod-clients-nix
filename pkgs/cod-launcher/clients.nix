{
  lib,
  callPackage,
  proton-ge-bin,
  alterware-launcher,
  unzip,
}:

{
  protonPath ? "${proton-ge-bin.steamcompattool}",
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
  cblauncherExtraArgs ? [ ],
  cblauncherExtraWinetricks ? [ ],
  cblauncherGameDirs ? [ ],
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

  mkAlterware =
    {
      name,
      desktopName,
      code,
      appid,
      exe,
      modes ? [ ],
      desktopEntry ? true,
    }:
    mk {
      inherit
        name
        desktopName
        sandbox
        protonPath
        desktopEntry
        ;
      extraRuntimeInputs = [ alterware-launcher ];
      extraArgs = modes;
      env = { };
      acquire = ''
        gamedir="$(resolve_steam_dir ${appid} || true)"
        if [ -z "$gamedir" ] || [ ! -d "$gamedir" ]; then
          echo "cod-${name}: ${desktopName} base game not found (own + install it on Steam, app ${appid})" >&2
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
      desktopEntry ? true,
    }:
    mk {
      inherit
        name
        desktopName
        sandbox
        protonPath
        url
        exe
        extraArgs
        winetricks
        desktopEntry
        ;
      env = { };
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
    inherit protonPath;
    winetricks =
      plutoniumBaseVerbs ++ lib.optional plutoniumDotnet "dotnet472" ++ plutoniumExtraWinetricks;
    env = lib.optionalAttrs plutoniumDotnet { WINEDLLOVERRIDES = "mscoree="; };
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
  };

  hmw = mk {
    name = "hmw";
    desktopEntry = desktopEntries.hmw or true;
    inherit sandbox;
    desktopName = "Horizon MW";
    inherit protonPath;
    extraRuntimeInputs = [ unzip ];
    winetricks = [
      "vcrun2022"
      "corefonts"
      "dotnetdesktop8"
    ]
    ++ hmwExtraWinetricks;
    env = { };
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
  };

  cblauncher = mk {
    name = "cblauncher";
    desktopEntry = desktopEntries.cblauncher or true;
    inherit sandbox;
    desktopName = "CB Launcher";
    inherit protonPath;
    url = "https://github.com/CBServers/updater/raw/main/updater/cb-launcher/cb-launcher.exe";
    exe = "cb-launcher.exe";
    winetricks = [
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
    ]
    ++ cblauncherExtraWinetricks;
    env = { };
    extraArgs = [
      "-portable"
      "--in-process-gpu"
      "--disable-gpu"
      "--disable-gpu-compositing"
    ]
    ++ cblauncherExtraArgs;
    preLaunch = ''
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
  };
  iw6 = mkAlterware {
    name = "iw6";
    desktopEntry = desktopEntries.iw6 or true;
    desktopName = "Call of Duty: Ghosts (iw6-mod)";
    code = "iw6-mod";
    appid = "209160";
    exe = "iw6-mod.exe";
    modes = [ "-multiplayer" ];
  };
  s1 = mkAlterware {
    name = "s1";
    desktopEntry = desktopEntries.s1 or true;
    desktopName = "Call of Duty: Advanced Warfare (s1-mod)";
    code = "s1-mod";
    appid = "209650";
    exe = "s1-mod.exe";
    modes = [ "-multiplayer" ];
  };
  iw2 = mkAlterware {
    name = "iw2";
    desktopEntry = desktopEntries.iw2 or true;
    desktopName = "Call of Duty 2 (iw2-mod)";
    code = "iw2-mod";
    appid = "2630";
    exe = "iw2-mod.exe";
    modes = [ ];
  };
}
