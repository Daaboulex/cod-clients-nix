{
  lib,
  writeShellApplication,
  curl,
  coreutils,
  gnugrep,
}:

{ resolver }:

writeShellApplication {
  name = "cod-steamlink";
  runtimeInputs = [
    curl
    coreutils
    gnugrep
  ];
  text = ''
    ${resolver}

    appid="202970"
    exe="t6mp.exe"
    gamedir=""
    undo=0
    while [ "$#" -gt 0 ]; do
      case "$1" in
      --appid)
        appid="''${2:?--appid needs a value}"
        shift 2
        ;;
      --exe)
        exe="''${2:?--exe needs a value}"
        shift 2
        ;;
      --dir)
        gamedir="''${2:?--dir needs a value}"
        shift 2
        ;;
      --undo)
        undo=1
        shift
        ;;
      -h | --help)
        echo "usage: cod-steamlink [--appid N] [--exe NAME] [--dir PATH] [--undo]"
        echo "default: --appid 202970 (Black Ops II) --exe t6mp.exe"
        exit 0
        ;;
      *)
        echo "cod-steamlink: unknown argument: $1" >&2
        exit 1
        ;;
      esac
    done

    if [ -z "$gamedir" ]; then
      gamedir="$(resolve_steam_dir "$appid" || true)"
    fi
    if [ -z "$gamedir" ] || [ ! -d "$gamedir" ]; then
      echo "cod-steamlink: game dir for app $appid not found in any Steam library." >&2
      echo "Pass --dir /path/to/game if it lives somewhere unusual." >&2
      exit 1
    fi

    target="$gamedir/$exe"
    backup="$gamedir/$exe.cod-orig"

    if [ "$undo" -eq 1 ]; then
      if [ -f "$backup" ]; then
        chmod +w "$target" 2>/dev/null || true
        if ! cp -f "$backup" "$target"; then
          echo "cod-steamlink: restore failed -- if the file is immutable, run: sudo chattr -i \"$target\" then retry --undo" >&2
          exit 1
        fi
        echo "cod-steamlink: restored $exe from backup."
      else
        echo "cod-steamlink: no backup at $backup; nothing to undo." >&2
        exit 1
      fi
      exit 0
    fi

    if [ ! -f "$target" ]; then
      echo "cod-steamlink: $target not found -- is the game installed?" >&2
      exit 1
    fi

    state="''${XDG_DATA_HOME:-$HOME/.local/share}/cod-clients/plutonium"
    pluto="$state/plutonium.exe"
    if [ ! -f "$pluto" ]; then
      mkdir -p "$state"
      echo "cod-steamlink: fetching the official Plutonium launcher"
      curl -fL --remove-on-error --output "$pluto" "https://cdn.plutonium.pw/updater/plutonium.exe"
    fi

    if [ ! -f "$backup" ]; then
      cp -f --no-preserve=mode "$target" "$backup"
      echo "cod-steamlink: backed up $exe -> $exe.cod-orig"
    fi
    chmod +w "$target" 2>/dev/null || true
    cp -f --no-preserve=mode "$pluto" "$target"
    chmod -w "$target"

    echo "cod-steamlink: $exe now launches Plutonium; Steam 'Play' will track hours."
    echo "To keep it across Steam auto-updates, run this yourself:"
    echo "  sudo chattr +i \"$target\""
    echo "Undo any time: cod-steamlink --undo --appid $appid --exe $exe"
  '';
  meta = {
    description = "Steam hours-tracking helper (reversible exe-swap for Plutonium) for NixOS";
    homepage = "https://github.com/Daaboulex/cod-clients-nix";
    license = lib.licenses.mit;
    mainProgram = "cod-steamlink";
    platforms = [ "x86_64-linux" ];
  };
}
