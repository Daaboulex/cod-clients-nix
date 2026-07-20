{
  lib,
  writeShellApplication,
  umu-launcher,
  proton-ge-bin,
  bubblewrap,
  curl,
  coreutils,
  gnugrep,
  makeDesktopItem,
  symlinkJoin,
}:

{
  name,
  desktopName,
  exe ? "",
  url ? "",
  acquire ? "",
  extraRuntimeInputs ? [ ],
  protonPath ? "${proton-ge-bin.steamcompattool}",
  winetricks ? [ ],
  env ? { },
  preLaunch ? "",
  extraArgs ? [ ],
  sandbox ? true,
  icon ? "input-gaming",
  categories ? [ "Game" ],
}:

let
  steamResolver = import ./steam-resolve.nix;
  sandboxFn = import ./sandbox.nix;
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
      bubblewrap
      curl
      coreutils
      gnugrep
    ]
    ++ extraRuntimeInputs;
    text = ''
      ${steamResolver}
      ${sandboxFn}
      export COD_SANDBOX="''${COD_SANDBOX:-${if sandbox then "1" else "0"}}"

      state="''${XDG_DATA_HOME:-$HOME/.local/share}/cod-clients/${name}"
      mkdir -p "$state"
      cd "$state"
      gamedir=""
      gamedir_rw=""
      run=""

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
          COD_SANDBOX=0 umu-run winetricks -q ${verbStr}
          touch "$state/${marker}"
        fi
      ''}
      ${lib.optionalString (url != "") ''
        if [ ! -f "$state/${exe}" ]; then
          echo "cod-${name}: fetching the official client from ${url}"
          curl -fL --output "$state/${exe}" "${url}"
        fi
        run="$state/${exe}"
      ''}
      ${acquire}
      ${preLaunch}

      if [ -z "$run" ]; then
        echo "cod-${name}: could not resolve a client executable to run" >&2
        exit 1
      fi

      cod_launch umu-run "$run" ${argsStr}
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
    description = "${desktopName} launcher (umu-launcher + Proton, bubblewrap-sandboxed) for NixOS";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
    mainProgram = "cod-${name}";
  };
}
