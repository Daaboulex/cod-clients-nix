{
  lib,
  writeShellApplication,
  writeText,
  umu-launcher,
  proton-ge-bin,
  bubblewrap,
  curl,
  coreutils,
  gnugrep,
  icoutils,
  procps,
  util-linux,
  xrandr,
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
  gameSettings ? { },
  virtualDesktop ? { },
  subWatch ? { },
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

  keyOk =
    s:
    if lib.hasInfix "[" s || lib.hasInfix "]" s || lib.hasInfix "\n" s || lib.hasInfix "\"" s then
      throw "cod-${name}: invalid registry path segment: ${s}"
    else
      s;
  regEsc = lib.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ];
  managedExes = lib.attrNames (lib.filterAttrs (_: gs: (gs.registry or { }) != { }) gameSettings);
  regBody = lib.concatStrings (
    lib.mapAttrsToList (
      gsExe: gs:
      lib.optionalString ((gs.registry or { }) != { }) (
        "[-HKEY_CURRENT_USER\\Software\\Wine\\AppDefaults\\${keyOk gsExe}]\n\n"
        + lib.concatStrings (
          lib.mapAttrsToList (
            subkey: vals:
            "[HKEY_CURRENT_USER\\Software\\Wine\\AppDefaults\\${keyOk gsExe}${
              lib.optionalString (subkey != "") "\\${keyOk subkey}"
            }]\n"
            + lib.concatStrings (lib.mapAttrsToList (vn: vd: "\"${regEsc vn}\"=\"${regEsc vd}\"\n") vals)
            + "\n"
          ) gs.registry
        )
      )
    ) gameSettings
  );
  gsHash = builtins.substring 0 12 (builtins.hashString "sha256" (builtins.toJSON gameSettings));
  regFile = writeText "cod-${name}-gamesettings.reg" regBody;
  dxvkSections = lib.concatStrings (
    lib.mapAttrsToList (
      gsExe: gs: lib.optionalString ((gs.dxvk or "") != "") "[${keyOk gsExe}]\n${gs.dxvk}\n"
    ) gameSettings
  );
  dxvkConf = writeText "cod-${name}-dxvk.conf" dxvkSections;
  resOk =
    s:
    if builtins.match "[0-9]+x[0-9]+" s == null then
      throw "cod-${name}: invalid virtualDesktop resolution '${s}' (expected WIDTHxHEIGHT)"
    else
      s;
  vdName = "cod-${name}";
  vdResBaked =
    let
      v = lib.head (lib.attrValues virtualDesktop ++ [ "auto" ]);
    in
    if v == "auto" then "" else resOk v;
  vdOffBody =
    "[HKEY_CURRENT_USER\\Software\\Wine\\Explorer]\n\"Desktop\"=-\n\n"
    + "[HKEY_CURRENT_USER\\Software\\Wine\\Explorer\\Desktops]\n\"${vdName}\"=-\n";
  vdOffReg = writeText "cod-${name}-vdesktop-off.reg" (
    "Windows Registry Editor Version 5.00\n\n" + vdOffBody
  );

  subPattern = exe: lib.replaceStrings [ "." ] [ "\\." ] exe;

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
    ++ lib.optionals (subWatch != { }) [
      procps
      util-linux
    ]
    ++ lib.optional (virtualDesktop != { }) xrandr
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
      ${lib.optionalString (dxvkSections != "") ''
        export DXVK_CONFIG_FILE=${lib.escapeShellArg "${dxvkConf}"}
      ''}

      if [ -z "$PROTONPATH" ] || [ ! -f "$PROTONPATH/proton" ]; then
        echo "cod-${name}: no valid Proton (a directory containing 'proton') at: '$PROTONPATH'" >&2
        echo "Set protonPath to a Proton directory or \"steam\" (auto-detect newest in compatibilitytools.d), write a path or tool name to $proton_pref_file, or set COD_PROTON=<path>." >&2
        exit 1
      fi
      ${lib.optionalString (winetricks != [ ]) ''
        if [ ! -f "$state/${marker}" ]; then
          verbs_missing=()
          for verb in ${verbStr}; do
            grep -qxF "$verb" "$WINEPREFIX/winetricks.log" 2>/dev/null || verbs_missing+=("$verb")
          done
          if [ "''${#verbs_missing[@]}" -gt 0 ]; then
            echo "cod-${name}: prefix setup via winetricks (''${verbs_missing[*]})"
            for verb in "''${verbs_missing[@]}"; do
              if ! COD_SANDBOX=0 umu-run winetricks -q "$verb"; then
                case "$verb" in
                  dotnet*)
                    if [ -d "$WINEPREFIX/drive_c/windows/Microsoft.NET/Framework64/v4.0.30319" ]; then
                      echo "cod-${name}: $verb installer exited nonzero but the framework is on disk; continuing" >&2
                    else
                      echo "cod-${name}: $verb failed and no framework landed in the prefix" >&2
                      exit 1
                    fi
                    ;;
                  *)
                    echo "cod-${name}: winetricks verb $verb failed" >&2
                    exit 1
                    ;;
                esac
              fi
            done
          fi
          touch "$state/${marker}"
        fi
      ''}
      ${lib.optionalString (lib.any (v: lib.hasPrefix "dotnet" v) winetricks) ''
        if [ ! -f "$state/.netroot" ]; then
          COD_SANDBOX=0 umu-run reg add "HKLM\\Software\\Microsoft\\.NETFramework" /v InstallRoot /t REG_SZ /d "C:\\windows\\Microsoft.NET\\Framework64\\" /f
          COD_SANDBOX=0 umu-run reg add "HKLM\\Software\\Wow6432Node\\Microsoft\\.NETFramework" /v InstallRoot /t REG_SZ /d "C:\\windows\\Microsoft.NET\\Framework\\" /f
          touch "$state/.netroot"
        fi
      ''}
      if [ ! -f "$state/.steam-seeded-v2" ]; then
        echo "cod-${name}: seeding the Steam client into the prefix (boiii-lineage clients load steamclient64.dll)"
        COD_SANDBOX=0 umu-run reg add 'HKLM\Software\Wow6432Node\Valve\Steam' /v InstallPath /t REG_SZ /d 'C:\Program Files (x86)\Steam' /f
        steam_dir="$WINEPREFIX/drive_c/Program Files (x86)/Steam"
        mkdir -p "$steam_dir"
        legacy=""
        while IFS= read -r root; do
          if [ -f "$root/legacycompat/steamclient64.dll" ]; then
            legacy="$root/legacycompat"
            break
          fi
        done < <(_steam_roots)
        if [ -n "$legacy" ]; then
          for dll in steamclient64.dll steamclient.dll GameOverlayRenderer64.dll Steam.dll; do
            if [ -f "$legacy/$dll" ]; then cp -Lf "$legacy/$dll" "$steam_dir/"; fi
          done
          cp -Lf "$legacy/GameOverlayRenderer64.dll" "$steam_dir/gameoverlayrenderer64.dll" 2>/dev/null || true
          cp -Lf "$legacy/SteamService.exe" "$steam_dir/steam.exe" 2>/dev/null || touch "$steam_dir/steam.exe"
        else
          echo "cod-${name}: no Steam client legacycompat found; boiii/t7x/BO3 need the Steam client installed for their steamclient64.dll" >&2
          touch "$steam_dir/steam.exe"
        fi
        touch "$state/.steam-seeded-v2"
      fi
      gs_marker="$state/.gamesettings"
      if [ "$(head -n1 "$gs_marker" 2>/dev/null || true)" != "${gsHash}" ]; then
        gs_old="$(tail -n +2 "$gs_marker" 2>/dev/null || true)"
        if [ -n "$gs_old" ] || ${if regBody != "" then "true" else "false"}; then
          {
            printf 'Windows Registry Editor Version 5.00\n\n'
            while IFS= read -r gs_exe; do
              [ -n "$gs_exe" ] && printf '%s\n\n' "[-HKEY_CURRENT_USER\\Software\\Wine\\AppDefaults\\$gs_exe]"
            done <<< "$gs_old"
            cat ${regFile}
          } > "$state/gamesettings.reg"
          echo "cod-${name}: applying per-game Wine settings"
          COD_SANDBOX=0 umu-run regedit /S "$state/gamesettings.reg"
        fi
        {
          printf '%s\n' ${lib.escapeShellArg gsHash}
          ${lib.concatMapStrings (e: "printf '%s\\n' ${lib.escapeShellArg e}\n") managedExes}
        } > "$gs_marker"
      fi
      ${lib.optionalString (virtualDesktop != { }) ''
                if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
                  vd_res=${lib.escapeShellArg vdResBaked}
                  if [ -z "$vd_res" ]; then
                    vd_res="$(xrandr --current 2>/dev/null | awk '/[0-9]x[0-9]+.*\*/{print $1; exit}')"
                  fi
                  case "$vd_res" in
                    [0-9]*x[0-9]*) : ;;
                    *) vd_res="1920x1080" ;;
                  esac
                  vd_want="on-$vd_res"
                  cat > "$state/vdesktop-on.reg" <<EOF
        Windows Registry Editor Version 5.00

        [HKEY_CURRENT_USER\Software\Wine\Explorer]
        "Desktop"="${vdName}"

        [HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
        "${vdName}"="$vd_res"
        EOF
                  vd_reg="$state/vdesktop-on.reg"
                else
                  vd_want="off"
                  vd_reg=${vdOffReg}
                fi
                if [ "$(head -n1 "$state/.vdesktop" 2>/dev/null || true)" != "$vd_want" ]; then
                  echo "cod-${name}: syncing the Wine virtual desktop to this session type ($vd_want)"
                  COD_SANDBOX=0 umu-run regedit /S "$vd_reg"
                  printf '%s\n' "$vd_want" > "$state/.vdesktop"
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

      ${
        if subWatch == { } then
          ''
            cod_launch umu-run "$run" ${argsStr} "$@"
          ''
        else
          ''
            (cod_launch umu-run "$run" ${argsStr} "$@") &
            cod_main=$!
            declare -A cod_routed
            while kill -0 "$cod_main" 2>/dev/null; do
              ${lib.concatStrings (
                lib.mapAttrsToList (exe: bin: ''
                  while IFS= read -r cod_pid; do
                    [ -n "$cod_pid" ] || continue
                    [ -n "''${cod_routed[$cod_pid]:-}" ] && continue
                    grep -zqs "WINEPREFIX=$WINEPREFIX" "/proc/$cod_pid/environ" || continue
                    cod_args="$(tr '\0' '\n' < "/proc/$cod_pid/cmdline" 2>/dev/null | tail -n +2 | tr '\n' ' ')" || cod_args=""
                    kill "$cod_pid" 2>/dev/null || true
                    cod_routed[$cod_pid]=1
                    echo "cod-${name}: rerouting ${exe} to its own Proton prefix"
                    read -r -a cod_argv <<< "$cod_args" || true
                    cod_sub_bin=${lib.escapeShellArg bin}
                    cod_sub_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/cod-clients/''${cod_sub_bin##*/cod-}"
                    mkdir -p "$cod_sub_dir"
                    setsid "$cod_sub_bin" "''${cod_argv[@]}" >> "$cod_sub_dir/launch.log" 2>&1 < /dev/null &
                  done < <(pgrep -f ${lib.escapeShellArg (subPattern exe)} 2>/dev/null || true)
                '') subWatch
              )}
              sleep 0.3
            done
            wait "$cod_main"
          ''
      }
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
