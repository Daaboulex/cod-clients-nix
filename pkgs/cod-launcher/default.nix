{
  lib,
  writeShellApplication,
  umu-launcher,
  proton-ge-bin,
  curl,
  coreutils,
  gnugrep,
  makeDesktopItem,
  symlinkJoin,
}:

{
  name,
  desktopName,
  exe,
  url,
  protonPath ? "${proton-ge-bin.steamcompattool}",
  winetricks ? [ ],
  env ? { },
  preLaunch ? "",
  extraArgs ? [ ],
  icon ? "input-gaming",
  categories ? [ "Game" ],
}:

let
  verbStr = lib.concatStringsSep " " winetricks;
  marker = ".prefix-" + builtins.substring 0 12 (builtins.hashString "sha256" verbStr);
  envExports = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "export ${k}=${lib.escapeShellArg v}") env
  );
  argsStr = lib.escapeShellArgs extraArgs;

  launcher = writeShellApplication {
    name = "cod-${name}";
    runtimeInputs = [
      umu-launcher
      curl
      coreutils
      gnugrep
    ];
    text = ''
      state="''${XDG_DATA_HOME:-$HOME/.local/share}/cod-clients/${name}"
      mkdir -p "$state"

      export WINEPREFIX="$state/pfx"
      export GAMEID="umu-cod-${name}"
      export STORE="none"
      export PROTONPATH="${protonPath}"
      ${envExports}

      if [ ! -d "$PROTONPATH" ]; then
        echo "cod-${name}: PROTONPATH is not a directory: $PROTONPATH" >&2
        echo "Set myModules.home.codClients.protonPath to a valid Proton directory." >&2
        exit 1
      fi
      ${lib.optionalString (winetricks != [ ]) ''
        if [ ! -f "$state/${marker}" ]; then
          echo "cod-${name}: first-run prefix setup via winetricks (${verbStr})"
          umu-run winetricks -q ${verbStr}
          touch "$state/${marker}"
        fi
      ''}
      if [ ! -f "$state/${exe}" ]; then
        echo "cod-${name}: fetching the official client from ${url}"
        curl -fL --output "$state/${exe}" "${url}"
      fi

      run="$state/${exe}"
      ${preLaunch}

      exec umu-run "$run" ${argsStr}
    '';
  };

  desktop = makeDesktopItem {
    name = "cod-${name}";
    inherit desktopName icon categories;
    exec = "cod-${name}";
    terminal = false;
  };
in
symlinkJoin {
  name = "cod-${name}";
  paths = [
    launcher
    desktop
  ];
  meta = {
    description = "${desktopName} launcher (umu-launcher + Proton) for NixOS";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
    mainProgram = "cod-${name}";
  };
}
