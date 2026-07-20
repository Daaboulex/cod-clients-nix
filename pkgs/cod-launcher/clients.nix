{
  lib,
  callPackage,
  proton-ge-bin,
  alterware-launcher,
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
  mw2crDir ? "",
  h2ExtraArgs ? [ ],
  sandbox ? true,
}:

let
  mk = callPackage ./. { };
  steamResolver = import ./steam-resolve.nix;
  steamlinkPkg = (callPackage ./steamlink.nix { }) { resolver = steamResolver; };
  steamaddPkg = callPackage ./steam-add.nix { };
  cleanopsPkg = (callPackage ./cleanops.nix { }) { resolver = steamResolver; };

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
    }:
    mk {
      inherit
        name
        desktopName
        sandbox
        protonPath
        ;
      extraRuntimeInputs = [ alterware-launcher ];
      extraArgs = modes;
      env = {
        PROTON_USE_NTSYNC = "1";
        PROTON_USE_WOW64 = "1";
      };
      acquire = ''
        gamedir="$(resolve_steam_dir ${appid} || true)"
        if [ -z "$gamedir" ] || [ ! -d "$gamedir" ]; then
          echo "cod-${name}: ${desktopName} base game not found (own + install it on Steam, app ${appid})" >&2
          exit 1
        fi
        echo "cod-${name}: updating ${code} via alterware-launcher"
        alterware-launcher ${code} -p "$gamedir" -u
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
        ;
      env = {
        PROTON_USE_NTSYNC = "1";
        PROTON_USE_WOW64 = "1";
      };
      preLaunch = ''
        gd="${dirOverride}"
        if [ -z "$gd" ]; then
          gd="$(resolve_steam_dir ${appid} || true)"
        fi
        if [ -z "$gd" ] || [ ! -d "$gd" ]; then
          echo "cod-${name}: ${gameName} not found (own + install it on Steam, app ${appid})" >&2
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
    inherit sandbox;
    desktopName = "Plutonium";
    url = "https://cdn.plutonium.pw/updater/plutonium.exe";
    exe = "plutonium.exe";
    inherit protonPath;
    winetricks =
      plutoniumBaseVerbs ++ lib.optional plutoniumDotnet "dotnet472" ++ plutoniumExtraWinetricks;
    env = {
      PROTON_USE_NTSYNC = "1";
      PROTON_USE_WOW64 = "1";
      PROTON_NO_ESYNC = "1";
      PROTON_NO_FSYNC = "1";
      DXVK_STATE_CACHE = "1";
    }
    // lib.optionalAttrs plutoniumDotnet { WINEDLLOVERRIDES = "mscoree="; };
    extraArgs = plutoniumExtraArgs;
  };

  t7x = mk {
    name = "t7x";
    inherit sandbox;
    desktopName = "Call of Duty: Black Ops III (t7x)";
    url = "https://master.bo3.eu/t7x/t7x.exe";
    exe = "t7x.exe";
    inherit protonPath;
    winetricks = t7xExtraWinetricks;
    env = {
      PROTON_USE_NTSYNC = "1";
      PROTON_USE_WOW64 = "1";
    };
    extraArgs = t7xExtraArgs;
    preLaunch = ''
      bo3="${blackOps3Dir}"
      if [ -z "$bo3" ]; then
        bo3="$(resolve_steam_dir 311210 || true)"
      fi
      if [ -z "$bo3" ] || [ ! -d "$bo3" ]; then
        echo "cod-t7x: Black Ops III not found (install it on Steam, app 311210) or set t7x.blackOps3Dir" >&2
        exit 1
      fi
      gamedir="$bo3"

      farm="$state/game"
      if [ ! -f "$state/.farm-ready" ]; then
        echo "cod-t7x: building the game farm from $bo3"
        rm -rf "$farm"
        mkdir -p "$farm"
        cp -rs "$bo3/." "$farm/"
        cp -f --remove-destination --no-preserve=mode "$bo3/BlackOps3.exe" "$farm/BlackOps3.exe"
        touch "$state/.farm-ready"
      fi
      ln -sfn "$state/t7x.exe" "$farm/t7x.exe"

      run="$farm/t7x.exe"
      cd "$farm" || exit 1
    '';
  };

  h1 = mkFarmClient {
    name = "h1";
    desktopName = "Call of Duty: Modern Warfare Remastered (h1-mod)";
    gameName = "Modern Warfare Remastered";
    appid = "393080";
    url = "https://github.com/auroramod/h1-mod/releases/latest/download/h1-mod.exe";
    exe = "h1-mod.exe";
    dirOverride = mwrDir;
    extraArgs = h1ExtraArgs;
  };

  h2 = mkFarmClient {
    name = "h2";
    desktopName = "Call of Duty: Modern Warfare 2 Campaign Remastered (h2-mod)";
    gameName = "Modern Warfare 2 Campaign Remastered";
    appid = "1213210";
    url = "https://h2-mod.alicent.cat/data/h2-mod.exe";
    exe = "h2-mod.exe";
    dirOverride = mw2crDir;
    extraArgs = h2ExtraArgs;
  };

  steamlink = steamlinkPkg;
  steamadd = steamaddPkg;
  cleanops = cleanopsPkg;

  iw5 = mkAlterware {
    name = "iw5";
    desktopName = "Call of Duty: Modern Warfare 3 (iw5-mod)";
    code = "iw5-mod";
    appid = "115300";
    exe = "iw5-mod.exe";
    modes = [ "-multiplayer" ];
  };
  iw6 = mkAlterware {
    name = "iw6";
    desktopName = "Call of Duty: Ghosts (iw6-mod)";
    code = "iw6-mod";
    appid = "209160";
    exe = "iw6-mod.exe";
    modes = [ "-multiplayer" ];
  };
  s1 = mkAlterware {
    name = "s1";
    desktopName = "Call of Duty: Advanced Warfare (s1-mod)";
    code = "s1-mod";
    appid = "209650";
    exe = "s1-mod.exe";
    modes = [ "-multiplayer" ];
  };
  iw2 = mkAlterware {
    name = "iw2";
    desktopName = "Call of Duty 2 (iw2-mod)";
    code = "iw2-mod";
    appid = "2630";
    exe = "iw2-mod.exe";
    modes = [ ];
  };
}
