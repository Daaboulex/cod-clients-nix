{
  lib,
  writeShellApplication,
  umu-launcher,
  proton-ge-bin,
  bubblewrap,
  curl,
  coreutils,
  gnugrep,
  icoutils,
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
  categories ? [ "Game" ],
  desktopEntry ? true,
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
      icoutils
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
      protonPath_baked=${lib.escapeShellArg protonPath}
      proton_pref_file="''${XDG_CONFIG_HOME:-$HOME/.config}/cod-clients/proton"
      proton_pref_client="''${XDG_CONFIG_HOME:-$HOME/.config}/cod-clients/${name}.proton"
      _proton_from_file() {
        local f="$1" pref root
        [ -f "$f" ] || return 1
        pref="$(head -n1 "$f")"
        [ -n "$pref" ] || return 1
        if [ -f "$pref/proton" ]; then
          printf '%s\n' "$pref"
          return 0
        fi
        while IFS= read -r root; do
          if [ -f "$root/compatibilitytools.d/$pref/proton" ]; then
            printf '%s\n' "$root/compatibilitytools.d/$pref"
            return 0
          fi
        done < <(_steam_roots)
        echo "cod-${name}: preferred Proton '$pref' (from $f) not found; falling back" >&2
        return 1
      }
      resolve_proton() {
        local root d host_arch
        if [ -n "''${COD_PROTON:-}" ]; then
          printf '%s\n' "$COD_PROTON"
          return 0
        fi
        _proton_from_file "$proton_pref_client" && return 0
        _proton_from_file "$proton_pref_file" && return 0
        if [ "$protonPath_baked" = steam ]; then
          host_arch="$(uname -m)"
          while IFS= read -r root; do
            for d in "$root"/compatibilitytools.d/*/; do
              [ -f "''${d}proton" ] || continue
              if [ "$host_arch" = x86_64 ] && [ -f "''${d}toolmanifest.vdf" ] && grep -qE 'require_tool_appid"[[:space:]]*"4185400"' "''${d}toolmanifest.vdf"; then
                continue
              fi
              printf '%s\n' "''${d%/}"
            done
          done < <(_steam_roots) | sort -V | tail -n1
          return 0
        fi
        printf '%s\n' "$protonPath_baked"
      }
      PROTONPATH="$(resolve_proton)"
      export PROTONPATH
      ${envExports}

      if [ -z "$PROTONPATH" ] || [ ! -f "$PROTONPATH/proton" ]; then
        echo "cod-${name}: no valid Proton (a directory containing 'proton') at: '$PROTONPATH'" >&2
        echo "Set protonPath to a Proton directory or \"steam\" (auto-detect newest in compatibilitytools.d), write a path or tool name to $proton_pref_file, or set COD_PROTON=<path>." >&2
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
          curl -fL --remove-on-error --output "$state/${exe}" "${url}"
        fi
        run="$state/${exe}"
      ''}
      ${acquire}
      ${preLaunch}

      if [ -z "$run" ] || [ ! -f "$run" ]; then
        echo "cod-${name}: no client executable to run at: '$run'" >&2
        exit 1
      fi

      icon_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
      icon_png="$icon_dir/cod-${name}.png"
      if [ ! -f "$icon_png" ]; then
        tmpico="$(mktemp -d)"
        if wrestool -x -t 14 "$run" -o "$tmpico/i.ico" 2>/dev/null && icotool -x -o "$tmpico" "$tmpico/i.ico" 2>/dev/null; then
          big=""
          big_sz=0
          for f in "$tmpico"/*.png; do
            [ -f "$f" ] || continue
            sz="$(stat -c%s "$f" 2>/dev/null || echo 0)"
            if [ "$sz" -gt "$big_sz" ]; then
              big_sz="$sz"
              big="$f"
            fi
          done
          if [ -n "$big" ]; then
            mkdir -p "$icon_dir"
            cp -f "$big" "$icon_png"
          fi
        fi
        rm -rf "$tmpico"
      fi

      cod_launch umu-run "$run" ${argsStr}
    '';
  };

  desktop = makeDesktopItem {
    name = "cod-${name}";
    inherit desktopName categories;
    icon = "cod-${name}";
    exec = "cod-${name}";
    terminal = false;
  };
in
symlinkJoin {
  name = "cod-${name}";
  paths = [
    launcher
  ]
  ++ lib.optional desktopEntry desktop;
  meta = {
    description = "${desktopName} launcher (umu-launcher + Proton, bubblewrap-sandboxed) for NixOS";
    homepage = "https://github.com/Daaboulex/cod-clients-nix";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
    mainProgram = "cod-${name}";
  };
}
