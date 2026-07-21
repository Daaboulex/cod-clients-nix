{
  lib,
  writeShellApplication,
  python3,
  coreutils,
  procps,
  jq,
}:

let
  resolver = import ./steam-resolve.nix;
  py = python3.withPackages (ps: [ ps.vdf ]);
in
writeShellApplication {
  name = "cod-steam-native";
  runtimeInputs = [
    py
    coreutils
    procps
    jq
  ];
  text = ''
    ${resolver}

    cmd="add"
    case "''${1:-}" in
    add | remove | list)
      cmd="$1"
      ;;
    -h | --help)
      echo "usage: cod-steam-native [add|remove|list]"
      echo "Registers set-up cod-* clients as Steam shortcuts that run their .exe under"
      echo "Steam's Proton (dropdown works), reusing each client's prepared prefix. Plutonium"
      echo "gets one shortcut per owned game+mode (best-effort plutonium:// direct-launch;"
      echo "the launcher may still open to pick the mode)."
      echo "Sets your newest GE-Proton as the compat tool and fetches official cover art."
      echo "Close Steam before add/remove; run each cod-<client> once first so its prefix + exe exist."
      exit 0
      ;;
    "")
      ;;
    *)
      echo "cod-steam-native: unknown argument: $1" >&2
      exit 1
      ;;
    esac

    if [ "$cmd" != list ]; then
      if pgrep -x steam >/dev/null 2>&1 || pgrep -x steamwebhelper >/dev/null 2>&1; then
        echo "cod-steam-native: Steam is running -- fully close it first (it rewrites its config on exit)." >&2
        exit 1
      fi
    fi

    state_root="''${XDG_DATA_HOME:-$HOME/.local/share}/cod-clients"

    compat="$(
      while IFS= read -r root; do
        for d in "$root"/compatibilitytools.d/*/; do
          [ -f "''${d}proton" ] && basename "''${d%/}"
        done
      done < <(_steam_roots) | sort -V | tail -n1
    )"

    if [ "$cmd" = add ] && [ -z "$compat" ]; then
      echo "cod-steam-native: no GE-Proton found in any Steam compatibilitytools.d." >&2
      echo "Steam needs a forced Proton to run these .exe shortcuts. Install GE-Proton (e.g. via ProtonPlus)," >&2
      echo "or set each shortcut's Compatibility tool by hand in Steam after adding." >&2
    fi

    shortcuts="[]"
    add_shortcut() {
      local name="$1" exe="$2" opts="$3" art="$4"
      [ -f "$exe" ] || return 0
      shortcuts="$(jq -c \
        --arg name "$name" --arg exe "$exe" --arg sd "$(dirname "$exe")" --arg opts "$opts" --arg art "$art" \
        '. + [{name: $name, exe: $exe, startdir: $sd, launchopts: $opts, art_appid: $art}]' <<< "$shortcuts")"
    }

    pluto_state="$state_root/plutonium"
    pluto_exe="$pluto_state/plutonium.exe"
    add_pluto() {
      local code="$1" title="$2" appid="$3"
      [ -f "$pluto_exe" ] || return 0
      [ -n "$(resolve_steam_dir "$appid" || true)" ] || return 0
      add_shortcut "$title" "$pluto_exe" \
        "STEAM_COMPAT_DATA_PATH=$pluto_state %command% plutonium://play/$code" "$appid"
    }
    if command -v cod-plutonium >/dev/null 2>&1; then
      add_pluto t6mp "Plutonium: Black Ops II Multiplayer" 202970
      add_pluto t6zm "Plutonium: Black Ops II Zombies" 202970
      add_pluto t4mp "Plutonium: World at War Multiplayer" 10090
      add_pluto t4sp "Plutonium: World at War Campaign" 10090
      add_pluto t5mp "Plutonium: Black Ops Multiplayer" 42700
      add_pluto t5sp "Plutonium: Black Ops Campaign" 42700
    fi

    add_farm() {
      local c="$1" name="$2" rel="$3" art="$4"
      command -v "cod-$c" >/dev/null 2>&1 || return 0
      add_shortcut "$name" "$state_root/$c/$rel" "STEAM_COMPAT_DATA_PATH=$state_root/$c %command%" "$art"
    }
    add_farm t7x "t7x: Black Ops III" "game/t7x.exe" 311210
    add_farm boiii "BOIII: Black Ops III" "game/boiii.exe" 311210
    add_farm h1 "h1-mod: Modern Warfare Remastered" "game/h1-mod.exe" 393080
    add_farm h2 "h2-mod: MW2 Campaign Remastered" "game/h2-mod.exe" 1213210

    if command -v cod-cblauncher >/dev/null 2>&1; then
      add_shortcut "CB Launcher" "$state_root/cblauncher/cb-launcher.exe" \
        "STEAM_COMPAT_DATA_PATH=$state_root/cblauncher %command% -portable --in-process-gpu" ""
    fi

    if [ "$cmd" = add ] && [ "$shortcuts" = "[]" ]; then
      echo "cod-steam-native: no set-up clients found. Run a cod-<client> at least once first" >&2
      echo "(so its prefix + .exe exist under $state_root), then re-run cod-steam-native." >&2
      exit 1
    fi

    roots_json="$(_steam_roots | jq -R -s -c 'split("\n") | map(select(length > 0))')"
    payload="$(jq -c -n --argjson roots "$roots_json" --arg compat "$compat" --argjson shortcuts "$shortcuts" \
      '{roots: $roots, compat_tool: $compat, shortcuts: $shortcuts}')"

    printf '%s' "$payload" | python3 ${./steam-native.py} "$cmd"
  '';
  meta = {
    description = "Register cod-* clients as Proton-native Steam shortcuts (per-mode, artwork) on NixOS";
    homepage = "https://github.com/Daaboulex/cod-clients-nix";
    license = lib.licenses.mit;
    mainProgram = "cod-steam-native";
    platforms = [ "x86_64-linux" ];
  };
}
